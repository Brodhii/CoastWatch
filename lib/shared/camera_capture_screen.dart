import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../services/location_service.dart';

class CameraCaptureScreen extends StatefulWidget {
  final String title;

  const CameraCaptureScreen({
    super.key,
    this.title = 'Pemotretan Bukti Pesisir',
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _initError;
  FlashMode _flashMode = FlashMode.auto;
  LocationResult? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamerasAndLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initCamerasAndLocation() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    // Acquire quick coastal location in background
    LocationService().getCurrentLocation().then((loc) {
      if (mounted) setState(() => _location = loc);
    }).catchError((_) {});

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _initError = 'Kamera hardware tidak ditemukan pada perangkat atau browser laptop ini.';
        });
        return;
      }

      // Default to back camera for mobile, or first camera (webcam) for laptop
      int cameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          cameraIndex = i;
          break;
        }
      }

      _selectedCameraIndex = cameraIndex;
      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Init error: $e');
      if (mounted) {
        String friendlyMessage = 'Gagal mengakses kamera: $e. Pastikan izin kamera telah diberikan di sistem/browser.';
        if (e.toString().contains('MissingPluginException')) {
          friendlyMessage = 'Plugin kamera baru ditambahkan saat aplikasi sedang berjalan di browser. Harap hentikan terminal (tekan "q"), lalu jalankan ulang "flutter run -d chrome" agar browser memuat driver kamera.';
        }
        setState(() {
          _isInitializing = false;
          _initError = friendlyMessage;
        });
      }
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    final previousController = _controller;
    if (previousController != null) {
      await previousController.dispose();
    }

    final CameraController newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = null;
        });
      }
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Controller initialize error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Kamera tidak dapat diinisialisasi: $e';
        });
      }
    }
  }

  Future<void> _onShutterPressed() async {
    final controller = _controller;
    // Jika controller kamera live belum siap (misal di web/laptop atau MissingPluginException),
    // langsung alihkan ke kamera sistem agar tombol shutter tetap berfungsi!
    if (controller == null || !controller.value.isInitialized) {
      await _pickFromSystemCamera();
      return;
    }

    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile picture = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, picture);
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menjepret foto live: $e. Membuka kamera sistem...'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
        setState(() => _isTakingPicture = false);
        // Fallback langsung ke picker kamera sistem
        await _pickFromSystemCamera();
      }
    }
  }

  /// Buka kamera bawaan sistem HP atau antarmuka kamera laptop (100% kompatibel Web & Mobile)
  Future<void> _pickFromSystemCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      debugPrint('[CameraCaptureScreen] System camera pick note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera tidak dapat diakses: $e. Pastikan izin kamera aktif.'),
            backgroundColor: AppTheme.statusRejected,
          ),
        );
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length <= 1) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    _initCameraController(_cameras[nextIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.auto;
    }

    try {
      await controller.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {
      // Some webcams and emulators do not support flash
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Viewfinder or Error / Loading State
            Positioned.fill(
              child: _buildCameraPreviewOrPlaceholder(),
            ),

            // 2. Viewfinder Overlay (Grid & Framing reticle)
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(
                child: _buildViewfinderOverlay(),
              ),

            // 3. Top Action Bar (Close, Live GPS Status, Flash)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // 4. Bottom Controls (Gallery, Shutter Button, Switch Camera)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreviewOrPlaceholder() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.teal),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke Sensor Kamera...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_initError != null || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kamera Langsung Tidak Terdeteksi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _initError ?? 'Webcam atau sensor kamera perangkat belum dapat diakses secara langsung pada laptop/browser ini.',
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Tombol 1: Buka Kamera Bawaan Sistem / Webcam
              ElevatedButton.icon(
                onPressed: _pickFromSystemCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text('Buka Kamera Langsung'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: AppTheme.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              // Tombol 2: Coba Sambungkan Kamera Lagi
              TextButton.icon(
                onPressed: _initCamerasAndLocation,
                icon: const Icon(Icons.refresh, size: 15, color: Colors.white60),
                label: const Text('Coba Sambungkan Sensor Kamera Lagi', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildViewfinderOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Rule of thirds grid lines
          Row(
            children: [
              const Spacer(flex: 1),
              Container(width: 0.6, color: Colors.white.withValues(alpha: 0.2)),
              const Spacer(flex: 1),
              Container(width: 0.6, color: Colors.white.withValues(alpha: 0.2)),
              const Spacer(flex: 1),
            ],
          ),
          Column(
            children: [
              const Spacer(flex: 1),
              Container(height: 0.6, color: Colors.white.withValues(alpha: 0.2)),
              const Spacer(flex: 1),
              Container(height: 0.6, color: Colors.white.withValues(alpha: 0.2)),
              const Spacer(flex: 1),
            ],
          ),

          // Central focus reticle
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Close button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // GPS Geotag status indicator badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // Emerald green
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _location != null && !_location!.isFallback
                    ? 'GPS Terkunci (±${_location!.accuracy.toStringAsFixed(0)}m)'
                    : 'Mencari Sinyal GPS...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Flash Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _flashMode == FlashMode.always
                  ? Icons.flash_on
                  : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_off),
              color: Colors.white,
              size: 20,
            ),
            onPressed: _toggleFlash,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Empty balanced spacer replacing gallery
          const SizedBox(width: 48, height: 48),

          // Main Shutter Button
          GestureDetector(
            onTap: _isTakingPicture ? null : _onShutterPressed,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _isTakingPicture ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _isTakingPicture
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.navy,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Switch camera (front / back)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 24),
              tooltip: 'Ganti Kamera',
              onPressed: (_cameras.length > 1 && !_isTakingPicture) ? _switchCamera : null,
            ),
          ),
        ],
      ),
    );
  }
}
