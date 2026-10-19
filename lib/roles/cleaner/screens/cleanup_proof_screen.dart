import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/exif_service.dart';
import '../../../services/location_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';
import '../../../shared/app_text_field.dart';
import '../../reporter/widgets/geotag_preview_card.dart';

class CleanupProofScreen extends StatefulWidget {
  final String reportId;

  const CleanupProofScreen({super.key, required this.reportId});

  @override
  State<CleanupProofScreen> createState() => _CleanupProofScreenState();
}

class _CleanupProofScreenState extends State<CleanupProofScreen> {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final ExifService _exifService = ExifService();
  final ReportService _reportService = ReportService();
  final TextEditingController _notesController = TextEditingController();

  File? _proofImageFile;
  LocationResult? _captureLocation;
  ExifDataResult? _exifResult;
  bool _isProcessing = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takeProofPhoto(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final loc = await _locationService.getCurrentLocation();
      _captureLocation = loc;

      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final file = File(picked.path);

      // Verify file size <= 5 MB (Section 7.3)
      final length = await file.length();
      if (length > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto bukti melebihi 5 MB. Harap kompresi foto.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final exif = await _exifService.extractExifData(file, fallbackLocation: loc);

      setState(() {
        _proofImageFile = file;
        _exifResult = exif;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('[CleanupProof] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses foto bukti: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _submitCleanupProof() async {
    if (_proofImageFile == null || _exifResult == null || !_exifResult!.isValid) {
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
        proofPhotoFile: _proofImageFile!,
        notes: _notesController.text.trim(),
        cleanupLat: _exifResult!.latitude!,
        cleanupLng: _exifResult!.longitude!,
        cleanupTimestamp: _exifResult!.dateTimeOriginal ?? DateTime.now(),
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
    final hasValidGps = _proofImageFile != null && (_exifResult?.isValid ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Bukti Pembersihan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppTheme.navy),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ambil foto kondisi pantai sesudah pembersihan langsung di lokasi. Foto bukti harus ber-geotag valid dari sensor GPS.',
                      style: TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (report != null) ...[
              Text(
                'Tugas: ${report.categoryName} (${report.locationName ?? report.formattedCoordinates})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
            ],

            // Photo Capture Area
            if (_proofImageFile == null)
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _takeProofPhoto(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy,
                            foregroundColor: AppTheme.white,
                          ),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Buka Kamera'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _takeProofPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galeri'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _proofImageFile!,
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
                          onPressed: () => _takeProofPhoto(ImageSource.camera),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_exifResult != null)
                GeotagPreviewCard(
                  exifData: _exifResult!,
                  accuracy: _captureLocation?.accuracy,
                ),
            ],

            const SizedBox(height: 18),

            // Cleanup Action Notes
            AppTextField(
              label: 'Catatan Penanganan & Tindak Lanjut',
              hint: 'Contoh: Berhasil mengangkut 4 karung sampah plastik ke TPS, area mangrove telah bebas dari jaring.',
              controller: _notesController,
              maxLines: 3,
            ),

            const SizedBox(height: 28),

            AppButton(
              label: 'Kirim Bukti & Selesaikan Tugas',
              onPressed: hasValidGps && !_isSubmitting ? _submitCleanupProof : null,
              isLoading: _isSubmitting,
              icon: Icons.check_circle_outline,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
