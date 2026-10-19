import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/exif_service.dart';
import '../../../services/location_service.dart';
import '../../../shared/app_button.dart';
import '../widgets/geotag_preview_card.dart';

class CreateReportCameraScreen extends StatefulWidget {
  const CreateReportCameraScreen({super.key});

  @override
  State<CreateReportCameraScreen> createState() => _CreateReportCameraScreenState();
}

class _CreateReportCameraScreenState extends State<CreateReportCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final ExifService _exifService = ExifService();

  File? _imageFile;
  LocationResult? _captureLocation;
  ExifDataResult? _exifResult;
  bool _isProcessing = false;

  Future<void> _takePhoto(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Acquire current device location at capture time
      final loc = await _locationService.getCurrentLocation();
      _captureLocation = loc;

      // 2. Capture photo via Camera or Gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final file = File(pickedFile.path);

      // Check file size (max 5 MB as per Desain.md Section 7.3)
      final length = await file.length();
      if (length > AppConstants.maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto melebihi 5 MB. Harap gunakan foto dengan ukuran lebih kecil.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 3. Extract and validate EXIF GPS metadata
      final exif = await _exifService.extractExifData(file, fallbackLocation: loc);

      setState(() {
        _imageFile = file;
        _exifResult = exif;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('[CreateReport] Error taking photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses foto: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidPhotoAndGps = _imageFile != null && (_exifResult?.isValid ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langkah 1: Foto Bukti & Geotag'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
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
                      'Ambil foto temuan pesisir secara langsung di lokasi. Sistem membaca koordinat GPS dari sensor perangkat untuk validasi geotagging.',
                      style: TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo Preview or Camera Trigger Area
            if (_imageFile == null)
              Container(
                height: 240,
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
                      'Pastikan izin kamera dan GPS aktif',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _takePhoto(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy,
                            foregroundColor: AppTheme.white,
                          ),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Buka Kamera'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _takePhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galeri'),
                        ),
                      ],
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
                    Image.file(
                      _imageFile!,
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
                          onPressed: () => _takePhoto(ImageSource.camera),
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
              label: 'Lanjut ke Pilih Kategori',
              onPressed: hasValidPhotoAndGps
                  ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createReportForm,
                        arguments: {
                          'photoFile': _imageFile!,
                          'latitude': _exifResult!.latitude!,
                          'longitude': _exifResult!.longitude!,
                          'accuracy': _captureLocation?.accuracy ?? 15.0,
                          'photoTimestamp': _exifResult!.dateTimeOriginal ?? DateTime.now(),
                        },
                      );
                    }
                  : null,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
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
