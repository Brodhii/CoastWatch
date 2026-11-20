import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';
import '../../../shared/safe_app_image.dart';
import '../../../shared/status_badge.dart';
import '../widgets/before_after_preview.dart';

class CleanerTaskDetailScreen extends StatefulWidget {
  final String reportId;

  const CleanerTaskDetailScreen({super.key, required this.reportId});

  @override
  State<CleanerTaskDetailScreen> createState() => _CleanerTaskDetailScreenState();
}

class _CleanerTaskDetailScreenState extends State<CleanerTaskDetailScreen> {
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  bool _isClaiming = false;
  bool _isStartingFieldWork = false;
  double? _distanceMeters;
  bool _isLoadingLocation = true;
  bool _isSimulatingProximity = false;
  LocationResult? _cleanerLocation;

  // SOP & Field Checklist States
  final Set<int> _checkedSopIndices = {0, 1, 2, 3};
  final Set<int> _checkedFieldIndices = {0};

  @override
  void initState() {
    super.initState();
    _checkProximity();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkProximity() async {
    final report = _reportService.getReportById(widget.reportId);
    if (report == null) return;

    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;
      if (loc != null) {
        final dist = LocationService.calculateDistanceMeters(
          loc.latitude,
          loc.longitude,
          report.latitude,
          report.longitude,
        );
        setState(() {
          _cleanerLocation = loc;
          _distanceMeters = dist;
          _isLoadingLocation = false;
        });
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onClaimPressed(ReportModel report) {
    final bool isTooFar = !_isSimulatingProximity &&
        (_distanceMeters == null || _distanceMeters! > AppConstants.maxCleanerProximityMeters);

    if (isTooFar) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Konfirmasi Titik Lokasi Pesisir',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Text(
            'Lokasi Anda saat ini terdeteksi berjarak ${LocationService.formatDistance(_distanceMeters ?? 999999)} dari titik pantai ini.\n\n'
            'Relawan diwajibkan berada dalam radius maksimal 50 meter dari pantai untuk mengunci tugas pembersihan.\n\n'
            'Lanjutkan dengan mode simulasi uji coba?',
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
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
                _claimTask(report);
              },
              child: const Text('Ambil Tugas (Simulasi)'),
            ),
          ],
        ),
      );
      return;
    }

    _claimTask(report);
  }

  Future<void> _claimTask(ReportModel report) async {
    setState(() => _isClaiming = true);
    try {
      final success = await _reportService.claimTask(
        report.id,
        cleanerLat: _cleanerLocation?.latitude,
        cleanerLng: _cleanerLocation?.longitude,
        bypassProximity: _isSimulatingProximity,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diambil & dikunci atas nama Anda!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil tugas: $e'), backgroundColor: AppTheme.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _onStartFieldWorkPressed(ReportModel report) {
    final bool isTooFar = !_isSimulatingProximity &&
        (_distanceMeters == null || _distanceMeters! > AppConstants.maxCleanerProximityMeters);

    if (isTooFar) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Verifikasi Keberadaan di Pantai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Text(
            'Anda terdeteksi berjarak ${LocationService.formatDistance(_distanceMeters ?? 999999)} dari titik pantai.\n\n'
            'Apakah Anda ingin memulai aksi pembersihan dengan mode simulasi uji coba?',
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
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
                _startFieldWork(report);
              },
              child: const Text('Mulai (Simulasi)'),
            ),
          ],
        ),
      );
      return;
    }

    _startFieldWork(report);
  }

  Future<void> _startFieldWork(ReportModel report) async {
    setState(() => _isStartingFieldWork = true);
    try {
      await _reportService.startFieldWork(report.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aksi pembersihan lapangan dimulai!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai aksi lapangan: $e'), backgroundColor: AppTheme.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingFieldWork = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final report = _reportService.getReportById(widget.reportId);

        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Tugas')),
            body: const Center(child: Text('Data tugas tidak ditemukan.')),
          );
        }

        final currentUserId = _authService.currentUser.id;
        final isClaimedByMe = report.cleanupTask != null &&
            (report.cleanupTask?.cleanerId == currentUserId ||
                report.cleanupTask?.cleanerId == 'd0000000-0000-0000-0000-000000000002');
        final isClaimedByOther = report.cleanupTask != null && !isClaimedByMe;
        final isAvailableToClaim = report.isAvailableForCleanup;
        final isCompleted = report.status == ReportStatus.cleaned;

        int activeStep = 1;
        if (report.status == ReportStatus.verified && isAvailableToClaim) {
          activeStep = 1;
        } else if (report.status == ReportStatus.inProgress) {
          activeStep = report.isFieldWorkActive ? 2 : 1;
        } else if (report.status == ReportStatus.pendingCleanupReview) {
          activeStep = 3;
        } else if (report.status == ReportStatus.cleaned) {
          activeStep = 4;
        }

        final regionName = report.locationName != null && report.locationName!.isNotEmpty
            ? report.locationName!
            : 'Kawasan Pesisir Pantai Batam';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Detail Tugas Pembersihan'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Minimalist Stepper Bar (No clashing rainbow background)
                _buildCleanStepper(activeStep),

                // Photo Evidence
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: SafeAppImage(
                    imageUrl: report.beforePhotoUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card: Category & Wilayah
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    report.categoryName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: report.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0F766E)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    regionName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (report.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),
                              Text(
                                report.description,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location & Navigation Preview Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Peta Titik Pesisir',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  if (_distanceMeters != null)
                                    Text(
                                      'Jarak: ${LocationService.formatDistance(_distanceMeters!)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                                    ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(9),
                                bottomRight: Radius.circular(9),
                              ),
                              child: SizedBox(
                                height: 160,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(report.latitude, report.longitude),
                                    initialZoom: 14.5,
                                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: AppConstants.osmTileUrl,
                                      userAgentPackageName: AppConstants.osmUserAgent,
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(report.latitude, report.longitude),
                                          width: 32,
                                          height: 32,
                                          child: const Icon(Icons.location_on, color: Color(0xFF0F172A), size: 32),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Before-After Preview (If cleaned or pending review)
                      if ((isCompleted || report.status == ReportStatus.pendingCleanupReview) && report.afterPhotoUrl != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BeforeAfterPreview(
                                beforePhotoUrl: report.beforePhotoUrl,
                                afterPhotoUrl: report.afterPhotoUrl!,
                                beforeLocation: regionName,
                                afterLocation: regionName,
                              ),
                              if (report.cleanupTask?.notes != null) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 10),
                                Text(
                                  'Catatan Relawan: ${report.cleanupTask!.notes}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Operational Action Panels
                      if (isAvailableToClaim) ...[
                        _buildClaimActionCard(report),
                      ] else if (isClaimedByOther && report.status == ReportStatus.inProgress) ...[
                        _buildLockedByOtherCard(report),
                      ] else if (isClaimedByMe && report.status == ReportStatus.inProgress) ...[
                        if (!report.isFieldWorkActive) ...[
                          _buildPhase1StandbyCard(report),
                        ] else ...[
                          _buildPhase2ActiveFieldCard(report),
                        ],
                      ] else if (report.status == ReportStatus.pendingCleanupReview) ...[
                        _buildPendingReviewCard(),
                      ] else if (isCompleted) ...[
                        _buildCleanedSuccessCard(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Clean, high-contrast, minimalist Stepper (Replaces clashing rainbow stepper)
  Widget _buildCleanStepper(int activeStep) {
    final steps = ['Persiapan', 'Aksi Lapangan', 'Bukti Bersih', 'Selesai'];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final stepNum = idx + 1;
          final isDone = activeStep > stepNum;
          final isCurrent = activeStep == stepNum;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF0F766E)
                              : (isCurrent ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF0F172A)
                                : (isDone ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1)),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[idx],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 14,
                    height: 2,
                    color: isDone ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.only(bottom: 14),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Claim Card for Available Task
  Widget _buildClaimActionCard(ReportModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi Pengambilan Tugas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Setelah mengambil tugas, lokasi pantai akan dikunci khusus untuk Anda agar relawan lain tidak menempuh perjalanan ke titik yang sama.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),
          _buildProximityRow(),
          const SizedBox(height: 14),
          AppButton(
            label: 'Ambil & Kunci Tugas Ini',
            onPressed: _isClaiming ? null : () => _onClaimPressed(report),
            isLoading: _isClaiming,
            icon: Icons.lock_outline,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  // TAHAP 1: STANDBY & SAFETY SOP
  Widget _buildPhase1StandbyCard(ReportModel report) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFF0F766E), width: 3.5),
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_rounded, size: 16, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tugas Terkunci Atas Nama Anda',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Relawan lain tidak dapat mengambil titik ini. Pastikan Anda mengenakan alat pelindung diri sebelum memulai aksi fisik:',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),

            _buildSopItem(0, 'Sarung tangan pelindung karet / kain tebal'),
            _buildSopItem(1, 'Masker pelindung debu & aroma pesisir'),
            _buildSopItem(2, 'Sepatu tertutup pelindung karang tajam'),
            _buildSopItem(3, 'Karung sampah dan penjepit sampah'),

            const SizedBox(height: 12),
            _buildProximityRow(),
            const SizedBox(height: 16),

            AppButton(
              label: 'Saya Sudah Tiba di Lokasi & Mulai Membersihkan',
              onPressed: _isStartingFieldWork ? null : () => _onStartFieldWorkPressed(report),
              isLoading: _isStartingFieldWork,
              icon: Icons.play_arrow_rounded,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSopItem(int index, String title) {
    final isChecked = _checkedSopIndices.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedSopIndices.remove(index);
          } else {
            _checkedSopIndices.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: isChecked ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAHAP 2: ACTIVE FIELD CLEANING MODE
  Widget _buildPhase2ActiveFieldCard(ReportModel report) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFF0284C7), width: 3.5),
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cleaning_services_outlined, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Pembersihan Sedang Berlangsung',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF0284C7)),
                    SizedBox(width: 5),
                    Text(
                      'Sedang Berlangsung',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Silakan bersihkan sampah di lokasi pesisir dan dokumentasikan foto hasil bersih setelah selesai.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),

          _buildFieldCheckItem(0, 'Kumpulkan seluruh sampah di area pesisir'),
          _buildFieldCheckItem(1, 'Pisahkan sampah plastik dan limbah pecahan tajam / B3'),
          _buildFieldCheckItem(2, 'Kemas dan amankan sampah agar tidak terbawa angin dan ombak pesisir'),

          const SizedBox(height: 16),

          AppButton(
            label: 'Pembersihan Selesai → Unggah Foto Bukti',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.cleanupProof,
                arguments: report.id,
              );
            },
            icon: Icons.camera_alt_outlined,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFieldCheckItem(int index, String title) {
    final isChecked = _checkedFieldIndices.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedFieldIndices.remove(index);
          } else {
            _checkedFieldIndices.add(index);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isChecked ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Locked Card for other cleaners
  Widget _buildLockedByOtherCard(ReportModel report) {
    final cleanerName = report.cleanerName ?? 'Relawan Lain';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFFDC2626), width: 3.5),
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sedang Dikerjakan oleh $cleanerName (Terkunci)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Titik ini sedang dibersihkan oleh rekan relawan Anda. Akses tugas dikunci agar Anda tidak membuang waktu dan tenaga menuju lokasi yang sama.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Daftar Tugas Tersedia'),
            ),
          ],
        ),
      ),
    );
  }

  // Pending Review Card
  Widget _buildPendingReviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFF7C3AED), width: 3.5),
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menunggu Pengesahan Admin Operasional',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Foto bukti hasil pembersihan telah berhasil diajukan dan sedang dalam antrean verifikasi akhir admin.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cleaned Success Card
  Widget _buildCleanedSuccessCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFF16A34A), width: 3.5),
            top: BorderSide(color: Color(0xFFE2E8F0)),
            right: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.task_alt, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pembersihan Pantai Telah Sah & Selesai',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximityRow() {
    if (_isLoadingLocation) {
      return const Row(
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E))),
          SizedBox(width: 8),
          Text('Memeriksa posisi Anda...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      );
    }

    final isWithinRange = _isSimulatingProximity ||
        (_distanceMeters != null && _distanceMeters! <= AppConstants.maxCleanerProximityMeters);

    final distanceStr = _distanceMeters != null
        ? LocationService.formatDistance(_distanceMeters!)
        : 'Tidak terdeteksi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isWithinRange ? Icons.near_me_rounded : Icons.location_off_outlined,
              size: 15,
              color: isWithinRange ? const Color(0xFF0F766E) : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              isWithinRange ? 'Lokasi Valid ($distanceStr)' : 'Di Luar Radius ($distanceStr > 50m)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWithinRange ? const Color(0xFF0F766E) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        if (!isWithinRange) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _isSimulatingProximity = !_isSimulatingProximity),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _isSimulatingProximity,
                    activeColor: const Color(0xFF0F766E),
                    onChanged: (val) => setState(() => _isSimulatingProximity = val ?? false),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Simulasi Berada di Pantai (Mode Uji Coba)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
