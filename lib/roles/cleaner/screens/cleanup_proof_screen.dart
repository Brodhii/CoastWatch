import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/exif_service.dart';
import '../../../services/location_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';
import '../../../shared/app_text_field.dart';
import '../../../shared/camera_capture_screen.dart';
import '../../../shared/safe_app_image.dart';
import '../../reporter/widgets/geotag_preview_card.dart';
import '../widgets/before_after_preview.dart';

class CleanupProofScreen extends StatefulWidget {
  final String reportId;

  const CleanupProofScreen({super.key, required this.reportId});

  @override
  State<CleanupProofScreen> createState() => _CleanupProofScreenState();
}

class _CleanupProofScreenState extends State<CleanupProofScreen> {
  final LocationService _locationService = LocationService();
  final ExifService _exifService = ExifService();
  final ReportService _reportService = ReportService();
  final TextEditingController _notesController = TextEditingController();

  XFile? _proofXFile;
  Uint8List? _proofImageBytes;
  File? _proofImageFile;
  LocationResult? _captureLocation;
  ExifDataResult? _exifResult;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _isSimulatingProximity = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showLocationRequiredDialog({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppTheme.statusRejected, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: AppTheme.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Cek apakah layanan GPS aktif di perangkat
      final serviceEnabled = await _locationService.isServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showLocationRequiredDialog(
          title: 'Lokasi / GPS Belum Aktif',
          message: 'Relawan wajib mengaktifkan GPS perangkat untuk memvalidasi bahwa foto bukti pembersihan benar-benar diambil di lokasi pesisir.',
          actionLabel: 'Buka Pengaturan Lokasi',
          onAction: () async {
            await _locationService.openLocationSettings();
          },
        );
        return;
      }

      // 2. Cek izin lokasi
      var permission = await _locationService.checkPermissionStatus();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showLocationRequiredDialog(
          title: 'Izin Lokasi Diperlukan',
          message: 'Aplikasi CoastWatch membutuhkan izin lokasi nyata untuk memverifikasi pekerjaan pembersihan sampah pesisir oleh relawan.',
          actionLabel: permission == LocationPermission.deniedForever ? 'Buka Pengaturan Aplikasi' : 'Izinkan Lokasi',
          onAction: () async {
            if (permission == LocationPermission.deniedForever) {
              await _locationService.openAppSettings();
            } else {
              await _locationService.requestPermission();
            }
          },
        );
        return;
      }

      // 3. Ambil posisi GPS nyata perangkat secara akurat (strict = true)
      final loc = await _locationService.getCurrentLocation(strict: true);

      if (!mounted) return;
      final XFile? picture = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraCaptureScreen(
            title: 'Kamera Bukti Pembersihan',
          ),
        ),
      );

      if (picture == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      _captureLocation = loc;
      await _processImage(picture, loc);
    } catch (e) {
      debugPrint('[CleanupProof] Error opening camera / GPS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kendala GPS / Kamera: $e'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processImage(XFile file, LocationResult? loc) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.lengthInBytes > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto bukti melebihi 5 MB. Harap kompresi foto.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final exif = await _exifService.extractExifData(bytes, fallbackLocation: loc);

      if (mounted) {
        setState(() {
          _proofXFile = file;
          _proofImageBytes = bytes;
          if (!kIsWeb) {
            _proofImageFile = File(file.path);
          }
          _exifResult = exif;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[CleanupProof] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses foto bukti: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _onSendPressed(ReportModel? report, double? distanceMeters) {
    if (!_isSimulatingProximity && (distanceMeters == null || distanceMeters > AppConstants.maxCleanerProximityMeters)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppTheme.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text('Konfirmasi Lokasi Bukti Foto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Foto bukti yang diunggah terdeteksi berjarak '
            '${LocationService.formatDistance(distanceMeters ?? 999999)} dari koordinat laporan awal.\n\n'
            'Pada kondisi operasional lapangan asli, foto bukti wajib diambil dalam radius maksimal 50 meter dari titik sampah.\n\n'
            'Apakah Anda ingin mengirimkan bukti ini dengan mode simulasi (Uji Coba Laptop / Desktop)?',
            style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isSimulatingProximity = true);
                _submitCleanupProof();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: AppTheme.navy,
              ),
              child: const Text('Kirim Bukti (Simulasi)'),
            ),
          ],
        ),
      );
      return;
    }

    _submitCleanupProof();
  }

  Future<void> _submitCleanupProof() async {
    if ((_proofImageBytes == null && _proofImageFile == null) || _exifResult == null || !_exifResult!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti harus memiliki geotag GPS yang valid.'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
      return;
    }

    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tulis catatan singkat mengenai tindakan pembersihan yang dilakukan.'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _reportService.completeCleanupTask(
        reportId: widget.reportId,
        proofPhotoFile: _proofImageFile,
        proofPhotoXFile: _proofXFile,
        proofPhotoPath: _proofXFile?.path,
        notes: _notesController.text.trim(),
        cleanupLat: _exifResult!.latitude!,
        cleanupLng: _exifResult!.longitude!,
        cleanupTimestamp: _exifResult!.dateTimeOriginal ?? DateTime.now(),
        sackCount: 1,
        bypassProximity: _isSimulatingProximity,
      );

      if (!mounted) return;

      if (success) {
        final updatedReport = _reportService.getReportById(widget.reportId);
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.cleanupSuccess,
          arguments: updatedReport,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan tugas: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _reportService.getReportById(widget.reportId);
    final hasValidPhoto = (_proofImageBytes != null || _proofImageFile != null) && (_exifResult?.isValid ?? false);

    double? distanceMeters;
    if (_exifResult != null && _exifResult!.isValid && report != null) {
      distanceMeters = LocationService.calculateDistanceMeters(
        _exifResult!.latitude!,
        _exifResult!.longitude!,
        report.latitude,
        report.longitude,
      );
    }

    final isWithinRange = _isSimulatingProximity ||
        (distanceMeters != null && distanceMeters <= AppConstants.maxCleanerProximityMeters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Bukti Pembersihan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice Card (Clean white card with solid accent bar)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFF0F766E), width: 3.5),
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Color(0xFF0F766E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ambil foto kondisi pantai sesudah pembersihan di lokasi. Bukti akan diverifikasi oleh Admin Operasional.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (report != null) ...[
              Text(
                'Wilayah: ${report.locationName ?? "Kawasan Pesisir Pantai Batam"} • ${report.categoryName}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
            ],

            // Photo Capture Area
            if (_proofImageBytes == null && _proofImageFile == null)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cleaning_services_outlined, size: 52, color: AppTheme.teal),
                    const SizedBox(height: 10),
                    const Text(
                      'Ambil Foto Sesudah Bersih',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pastikan garis pantai/area bersih terlihat jelas',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _openCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Buka Kamera Langsung', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SafeAppImage(
                      imageBytes: _proofImageBytes,
                      imageUrl: (!kIsWeb && _proofImageFile != null) ? _proofImageFile!.path : null,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: AppTheme.white, size: 20),
                          onPressed: _openCamera,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_exifResult != null) ...[
                GeotagPreviewCard(
                  exifData: _exifResult!,
                  accuracy: _captureLocation?.accuracy,
                ),
                const SizedBox(height: 10),

                // Proximity Verification Card
                if (distanceMeters != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: isWithinRange ? const Color(0xFF0F766E) : const Color(0xFFDC2626),
                            width: 3.5,
                          ),
                          top: const BorderSide(color: Color(0xFFE2E8F0)),
                          right: const BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isWithinRange ? Icons.near_me_rounded : Icons.location_off_rounded,
                                size: 18,
                                color: isWithinRange ? const Color(0xFF0F766E) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isWithinRange
                                      ? 'Jarak Foto ke Pantai: ${LocationService.formatDistance(distanceMeters)} (Valid)'
                                      : 'Foto Di Luar Radius Titik Pantai (${LocationService.formatDistance(distanceMeters)} > 50m)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isWithinRange ? const Color(0xFF0F766E) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isWithinRange) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Foto bukti pembersihan harus diambil di lokasi pantai yang sama dengan laporan (maksimal 50 meter).',
                              style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isSimulatingProximity = !_isSimulatingProximity;
                                });
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _isSimulatingProximity,
                                      activeColor: const Color(0xFF0F766E),
                                      onChanged: (val) {
                                        setState(() {
                                          _isSimulatingProximity = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Simulasi Berada di Titik Lokasi Pantai (Mode Uji Coba)',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],

            if (report != null && hasValidPhoto) ...[
              const SizedBox(height: 18),
              BeforeAfterPreview(
                beforePhotoUrl: report.beforePhotoUrl,
                afterPhotoUrl: (!kIsWeb && _proofImageFile != null) ? _proofImageFile!.path : (_proofXFile?.path ?? report.beforePhotoUrl),
                afterPhotoBytes: _proofImageBytes,
                beforeLocation: report.locationName ?? 'Kondisi Awal Pesisir',
                afterLocation: report.locationName ?? 'Kondisi Sesudah Bersih',
              ),
            ],

            const SizedBox(height: 18),

            // Cleanup Action Notes / Deskripsi Penanganan
            AppTextField(
              label: 'Deskripsi Penanganan Pembersihan',
              hint: 'Tuliskan deskripsi tindakan pembersihan yang telah dilakukan di lokasi pesisir...',
              controller: _notesController,
              maxLines: 3,
            ),

            const SizedBox(height: 28),

            AppButton(
              label: 'Kirim Bukti untuk Validasi Admin',
              onPressed: (hasValidPhoto && !_isSubmitting) ? () => _onSendPressed(report, distanceMeters) : null,
              isLoading: _isSubmitting,
              icon: Icons.send_rounded,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
