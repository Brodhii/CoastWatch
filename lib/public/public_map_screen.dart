import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import '../shared/safe_app_image.dart';
import '../shared/status_badge.dart';

class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});

  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  final MapController _mapController = MapController();
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  String? _selectedCategoryId;
  ReportModel? _selectedReport;
  bool _showCleanedHistory = false;

  @override
  void initState() {
    super.initState();
    _centerToUserLocation();
  }

  Future<void> _centerToUserLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation(strict: false);
      if (mounted && loc != null && !loc.isFallback) {
        _mapController.move(LatLng(loc.latitude, loc.longitude), 14.5);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final reports = _reportService.getPublicReports(
          categoryId: _selectedCategoryId,
          showCleaned: _showCleanedHistory,
        );
        final categories = CategoryModel.defaultCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peta Laporan Publik'),
            actions: [
              IconButton(
                tooltip: 'Pusatkan ke Lokasi Saya',
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: () async {
                  try {
                    final myLoc = await _locationService.getCurrentLocation(strict: false);
                    if (myLoc != null) {
                      _mapController.move(LatLng(myLoc.latitude, myLoc.longitude), 15.0);
                    }
                  } catch (_) {
                    _mapController.move(
                      const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                      AppConstants.defaultZoom,
                    );
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // 1. FlutterMap OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
                  initialZoom: AppConstants.defaultZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedReport = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.osmTileUrl,
                    userAgentPackageName: AppConstants.osmUserAgent,
                    maxZoom: 19,
                  ),
                  // Markers for verified public reports & cleaned history
                  MarkerLayer(
                    markers: reports.map((report) {
                      final isSelected = _selectedReport?.id == report.id;
                      Color pinColor;
                      IconData pinIcon;

                      if (report.status == ReportStatus.cleaned) {
                        pinColor = const Color(0xFF15803D); // Emerald Green
                        pinIcon = Icons.eco_rounded;
                      } else if (report.status == ReportStatus.inProgress) {
                        pinColor = const Color(0xFFD97706); // Amber / Orange
                        pinIcon = Icons.cleaning_services_rounded;
                      } else {
                        pinColor = isSelected ? AppTheme.navy : AppTheme.teal;
                        pinIcon = Icons.location_on;
                      }

                      return Marker(
                        point: LatLng(report.latitude, report.longitude),
                        width: isSelected ? 48 : 38,
                        height: isSelected ? 48 : 38,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReport = report;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: pinColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              pinIcon,
                              color: AppTheme.white,
                              size: isSelected ? 26 : 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 2. Category Filter Chips (Top Overlay)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        label: 'Semua Kategori',
                        isSelected: _selectedCategoryId == null,
                        onSelected: () {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildFilterChip(
                              label: cat.name,
                              isSelected: _selectedCategoryId == cat.id,
                              onSelected: () {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // 2b. Toggle Riwayat Pantai Bersih (Floating Pill)
              Positioned(
                top: 58,
                right: 16,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showCleanedHistory = !_showCleanedHistory;
                        if (!_showCleanedHistory && _selectedReport?.status == ReportStatus.cleaned) {
                          _selectedReport = null;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showCleanedHistory ? const Color(0xFF15803D) : AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showCleanedHistory ? const Color(0xFF15803D) : const Color(0xFF15803D).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showCleanedHistory ? Icons.task_alt : Icons.eco_outlined,
                            size: 15,
                            color: _showCleanedHistory ? AppTheme.white : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Riwayat Pantai Bersih',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _showCleanedHistory ? AppTheme.white : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Attribution Note at Bottom-Left
              Positioned(
                bottom: _selectedReport != null ? 210 : 16,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    _showCleanedHistory
                        ? '© OpenStreetMap • Riwayat Pantai Bersih & Laporan Aktif'
                        : '© OpenStreetMap • Menampilkan Laporan Aktif yang Perlu Penanganan',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ),

              // 4. Selected Report Bottom Sheet / Card
              if (_selectedReport != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildReportSummaryCard(_selectedReport!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.navy : AppTheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildReportSummaryCard(ReportModel report) {
    final isCleaned = report.status == ReportStatus.cleaned;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCleaned ? const Color(0xFF15803D).withValues(alpha: 0.4) : AppTheme.border,
          width: isCleaned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category and Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail (Before, or Before-After side-by-side if cleaned)
              if (isCleaned && report.afterPhotoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeAppImage(imageUrl: report.beforePhotoUrl, fit: BoxFit.cover),
                        Container(
                          alignment: Alignment.bottomCenter,
                          color: Colors.black38,
                          child: const Text('Sebelum', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeAppImage(imageUrl: report.afterPhotoUrl!, fit: BoxFit.cover),
                        Container(
                          alignment: Alignment.bottomCenter,
                          color: const Color(0xAA15803D),
                          child: const Text('Bersih', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: SafeAppImage(imageUrl: report.beforePhotoUrl, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedReport = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.locationName != null && report.locationName!.isNotEmpty
                          ? report.locationName!
                          : 'Kawasan Pesisir Pantai Batam',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: report.status, isCompact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Jika pengguna login sebagai Relawan dan laporan siap ditangani
          if (_authService.currentRole == UserRole.cleaner && report.isAvailableForCleanup) ...[
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.cleanerTaskDetail,
                    arguments: report.id,
                  );
                },
                icon: const Icon(Icons.handyman_outlined, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: AppTheme.navy,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                label: const Text(
                  'Ambil & Bersihkan Sampah Ini',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else if (report.status == ReportStatus.inProgress) ...[
            // Status in_progress
            if (_authService.currentRole == UserRole.cleaner) ...[
              if (report.cleanupTask?.cleanerId == _authService.currentUser.id ||
                  report.cleanupTask?.cleanerId == 'd0000000-0000-0000-0000-000000000002') ...[
                // Claimed by CURRENT cleaner
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.cleanerTaskDetail,
                        arguments: report.id,
                      );
                    },
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: AppTheme.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    label: const Text(
                      'Lanjutkan Tugas Saya (Pembersihan)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Claimed by ANOTHER cleaner -> SHOW LOCKED BADGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Color(0xFFDC2626), width: 3),
                        top: BorderSide(color: Color(0xFFE2E8F0)),
                        right: BorderSide(color: Color(0xFFE2E8F0)),
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 15, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sedang Ditangani oleh ${report.cleanerName ?? "Relawan Lain"} (Terkunci)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ] else ...[
              // Visitor / Reporter viewing in-progress report
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Color(0xFF0284C7), width: 3),
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                      right: BorderSide(color: Color(0xFFE2E8F0)),
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cleaning_services_rounded, size: 15, color: Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sedang Dibersihkan oleh ${report.cleanerName ?? "Relawan CoastWatch"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ] else if (report.status == ReportStatus.pendingCleanupReview) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFF7C3AED), width: 3),
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fact_check_outlined, size: 15, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembersihan Selesai • Menunggu Pengesahan Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.publicReportDetail,
                  arguments: report.id,
                );
              },
              icon: Icon(
                isCleaned ? Icons.compare_arrows_rounded : Icons.arrow_forward_rounded,
                size: 16,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCleaned ? const Color(0xFF15803D) : AppTheme.navy,
                foregroundColor: AppTheme.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(
                isCleaned ? 'Lihat Bukti Bersih (Before-After)' : 'Lihat Detail Laporan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
