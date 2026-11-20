import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/exif_service.dart';
import '../../../services/location_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';
import '../../../shared/camera_capture_screen.dart';
import '../../../shared/status_badge.dart';
import '../widgets/geotag_preview_card.dart';

class CreateReportCameraScreen extends StatefulWidget {
  const CreateReportCameraScreen({super.key});

  @override
  State<CreateReportCameraScreen> createState() => _CreateReportCameraScreenState();
}

class _CreateReportCameraScreenState extends State<CreateReportCameraScreen> {
  final LocationService _locationService = LocationService();
  final ExifService _exifService = ExifService();
  final ReportService _reportService = ReportService();

  XFile? _capturedFile;
  Uint8List? _imageBytes;
  LocationResult? _captureLocation;
  ExifDataResult? _exifResult;
  bool _isProcessing = false;

  // Validasi pencegahan laporan duplikat (≤ 10 meter)
  ReportModel? _nearbyDuplicateReport;
  double? _duplicateDistanceMeters;
  bool _bypassDuplicateSimulation = false;

  @override
  void initState() {
    super.initState();
    // Relawan tidak memiliki otorisasi membuat laporan
    if (AuthService().currentRole == UserRole.cleaner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Relawan pembersih hanya bertugas membersihkan sampah dari laporan pelapor.'),
              backgroundColor: AppTheme.navy,
            ),
          );
        }
      });
    }
  }

  /// Buka Viewfinder Kamera interaktif CoastWatch (mendukung webcam laptop & kamera HP)
  Future<void> _openCamera() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Ambil lokasi GPS secara instan/background
      final locFuture = _locationService.getCurrentLocation();

      // 2. Buka layar kamera live viewfinder
      final XFile? picture = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraCaptureScreen(
            title: 'Kamera Bukti Pesisir',
          ),
        ),
      );

      if (picture == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final loc = await locFuture;
      _captureLocation = loc;
      await _processImageFile(picture, loc);
    } catch (e) {
      debugPrint('[CreateReport] Error opening camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kendala kamera: $e. Pastikan izin kamera aktif.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Memproses berkas foto (validasi ukuran, ekstraksi EXIF GPS, geotagging)
  Future<void> _processImageFile(XFile file, LocationResult? loc) async {
    try {
      final bytes = await file.readAsBytes();

      // Validasi ukuran berkas (maksimal 5 MB sesuai Desain.md Bagian 7.3)
      if (bytes.lengthInBytes > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto melebihi batas 5 MB. Harap gunakan foto dengan resolusi lebih ringkas.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Ekstraksi EXIF GPS dengan fallback ke sensor perangkat
      final exif = await _exifService.extractExifData(bytes, fallbackLocation: loc);

      // Cek apakah ada laporan aktif lain dalam radius 10 meter (pencegahan duplikat)
      ReportModel? duplicate;
      double? duplicateDist;
      if (exif.latitude != null && exif.longitude != null) {
        duplicate = _reportService.findNearbyActiveReport(
          exif.latitude!,
          exif.longitude!,
          radiusMeters: AppConstants.duplicateReportRadiusMeters,
        );
        if (duplicate != null) {
          duplicateDist = LocationService.calculateDistanceMeters(
            exif.latitude!,
            exif.longitude!,
            duplicate.latitude,
            duplicate.longitude,
          );
        }
      }

      if (mounted) {
        setState(() {
          _capturedFile = file;
          _imageBytes = bytes;
          _exifResult = exif;
          _nearbyDuplicateReport = duplicate;
          _duplicateDistanceMeters = duplicateDist;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[CreateReport] Error processing image bytes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses metadata foto: $e'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidPhotoAndGps = _imageBytes != null && (_exifResult?.isValid ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langkah 1: Foto Bukti & Geotag'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator (Step 1 of 3)
            _buildStepIndicator(currentStep: 1),
            const SizedBox(height: 16),

            // Instruction Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppTheme.navy),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Foto temuan pesisir wajib diambil langsung di lokasi menggunakan kamera. Akses galeri dinonaktifkan demi keaslian data ilmiah dan akurasi geotagging.',
                      style: TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo Preview or Camera Trigger Area
            if (_imageBytes == null)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_enhance_outlined,
                      size: 56,
                      color: AppTheme.teal,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada foto bukti',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Wajib ambil foto langsung di lokasi menggunakan kamera',
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
              // Image Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.memory(
                      _imageBytes!,
                      height: 220,
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
                          tooltip: 'Ambil Ulang Foto',
                          onPressed: _openCamera,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Geotag Validation Card
              if (_exifResult != null)
                GeotagPreviewCard(
                  exifData: _exifResult!,
                  accuracy: _captureLocation?.accuracy,
                ),

              // Peringatan Laporan Duplikat (Radius ≤ 10m)
              if (_nearbyDuplicateReport != null)
                _buildDuplicateWarningCard(),

              const SizedBox(height: 14),

              // Mini Map Context (Section 15.6: non-draggable pin)
              if (_exifResult != null && _exifResult!.isValid) ...[
                const Text(
                  'Pratinjau Lokasi di Peta Pesisir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_exifResult!.latitude!, _exifResult!.longitude!),
                        initialZoom: 14.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: AppConstants.osmTileUrl,
                          userAgentPackageName: AppConstants.osmUserAgent,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_exifResult!.latitude!, _exifResult!.longitude!),
                              width: 32,
                              height: 32,
                              child: const Icon(Icons.location_on, color: AppTheme.navy, size: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 28),

            // Next Step Button
            AppButton(
              label: (_nearbyDuplicateReport != null && !_bypassDuplicateSimulation)
                  ? 'Titik Sudah Dilaporkan (Terkunci)'
                  : 'Lanjut ke Pilih Kategori',
              onPressed: hasValidPhotoAndGps ? _onProceedToForm : null,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  void _onProceedToForm() {
    if (_nearbyDuplicateReport != null && !_bypassDuplicateSimulation) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('Laporan Duplikat Ditolak', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Titik ini berjarak ${_duplicateDistanceMeters?.toStringAsFixed(1) ?? '≤ 10'} meter '
            'dari laporan aktif (${_nearbyDuplicateReport!.id}) dengan status: ${_nearbyDuplicateReport!.status.label}.\n\n'
            'Untuk menjaga efisiensi relawan dan kebersihan basis data, warga lain tidak dapat mengirimkan laporan ganda di lokasi yang sama.\n\n'
            'Jika sedang menguji coba di laptop, Anda dapat mengaktifkan centang "Bypass Simulasi Duplikat".',
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  AppRoutes.publicReportDetail,
                  arguments: _nearbyDuplicateReport!.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: AppTheme.navy,
              ),
              child: const Text('Buka Laporan Tersebut'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.createReportForm,
      arguments: {
        'photoFile': _capturedFile != null && !kIsWeb ? File(_capturedFile!.path) : null,
        'photoXFile': _capturedFile,
        'imageBytes': _imageBytes,
        'photoPath': _capturedFile?.path ?? '',
        'latitude': _exifResult!.latitude!,
        'longitude': _exifResult!.longitude!,
        'accuracy': _captureLocation?.accuracy ?? 15.0,
        'photoTimestamp': _exifResult!.dateTimeOriginal ?? DateTime.now(),
        'bypassDuplicate': _bypassDuplicateSimulation,
      },
    );
  }

  Widget _buildDuplicateWarningCard() {
    if (_nearbyDuplicateReport == null) return const SizedBox.shrink();

    final report = _nearbyDuplicateReport!;
    final distText = _duplicateDistanceMeters != null
        ? '${_duplicateDistanceMeters!.toStringAsFixed(1)} meter'
        : '≤ 10 meter';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF87171), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Titik Lokasi Ini Sudah Dilaporkan!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Jarak $distText',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Laporan aktif lain ditemukan dalam radius 10 meter dari titik ini. '
            'Sampah pada titik ini sudah dilaporkan sebelumnya dan sedang dalam penanganan petugas/relawan.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${report.id}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kategori: ${report.categoryName}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: report.status, isCompact: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.publicReportDetail,
                      arguments: report.id,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Lihat Laporan yang Sedang Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() => _bypassDuplicateSimulation = !_bypassDuplicateSimulation);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _bypassDuplicateSimulation,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (val) {
                      setState(() => _bypassDuplicateSimulation = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Bypass Simulasi Duplikat (Mode Pengembang / Uji Coba Laptop)',
                    style: TextStyle(fontSize: 10, color: Color(0xFF991B1B), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      children: [
        _buildStepBadge(step: 1, label: 'Foto & Geotag', isActive: currentStep >= 1, isCurrent: currentStep == 1),
        Expanded(child: Container(height: 2, color: currentStep >= 2 ? AppTheme.navy : AppTheme.border)),
        _buildStepBadge(step: 2, label: 'Kategori', isActive: currentStep >= 2, isCurrent: currentStep == 2),
        Expanded(child: Container(height: 2, color: currentStep >= 3 ? AppTheme.navy : AppTheme.border)),
        _buildStepBadge(step: 3, label: 'Tinjau', isActive: currentStep >= 3, isCurrent: currentStep == 3),
      ],
    );
  }

  Widget _buildStepBadge({
    required int step,
    required String label,
    required bool isActive,
    required bool isCurrent,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppTheme.navy : AppTheme.border,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.white : AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
            color: isCurrent ? AppTheme.navy : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
