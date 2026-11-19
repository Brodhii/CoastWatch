import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_routes.dart';
import '../core/constants.dart';
import '../roles/cleaner/widgets/before_after_preview.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../shared/app_button.dart';
import '../shared/safe_app_image.dart';
import '../shared/status_badge.dart';

class PublicReportDetailScreen extends StatelessWidget {
  final String reportId;

  const PublicReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final authService = AuthService();
    final report = reportService.getReportById(reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(
          child: Text('Laporan tidak ditemukan.'),
        ),
      );
    }

    final targetDate = report.exifDateTimeOriginal ?? report.createdAt;
    String photoTimeStr;
    try {
      photoTimeStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(targetDate);
    } catch (_) {
      photoTimeStr = DateFormat('dd MMMM yyyy, HH:mm').format(targetDate);
    }

    final regionName = report.locationName != null && report.locationName!.isNotEmpty
        ? report.locationName!
        : 'Kawasan Pesisir Pantai Batam';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Laporan Pantai'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Photo Evidence
            AspectRatio(
              aspectRatio: 16 / 10,
              child: SafeAppImage(
                imageUrl: report.beforePhotoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Information Card
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              photoTimeStr,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        if (report.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          const Text(
                            'Deskripsi Temuan Lapangan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.description,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Map Card
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
                        const Padding(
                          padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Text(
                            'Titik Lokasi Pantai',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(9),
                            bottomRight: Radius.circular(9),
                          ),
                          child: SizedBox(
                            height: 180,
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

                  // In-Progress Notice (Clean white card with solid accent bar)
                  if (report.status == ReportStatus.inProgress) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Color(0xFF0284C7), width: 3.5),
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                            right: BorderSide(color: Color(0xFFE2E8F0)),
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cleaning_services_outlined, color: Color(0xFF0284C7), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sedang Dalam Proses Pembersihan',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ditangani oleh ${report.cleanerName ?? "relawan pembersih pesisir CoastWatch"}.',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Cleaned Notice & Before-After Comparison (Clean white card with solid green bar)
                  if (report.status == ReportStatus.cleaned && report.afterPhotoUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Color(0xFF16A34A), width: 3.5),
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                            right: BorderSide(color: Color(0xFFE2E8F0)),
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pantai Telah Berhasil Dibersihkan!',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          if (report.cleanupTask?.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Catatan relawan: "${report.cleanupTask!.notes}"',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          BeforeAfterPreview(
                            beforePhotoUrl: report.beforePhotoUrl,
                            afterPhotoUrl: report.afterPhotoUrl!,
                            beforeLocation: regionName,
                            afterLocation: regionName,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Cleaner Actions
                if (authService.currentRole == UserRole.cleaner) ...[
                  if (report.isAvailableForCleanup) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Ambil & Kerjakan Tugas Pembersihan Ini',
                      icon: Icons.lock_outline,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.cleanerTaskDetail,
                          arguments: report.id,
                        );
                      },
                    ),
                  ] else if (report.status == ReportStatus.inProgress) ...[
                    const SizedBox(height: 16),
                    if (report.cleanupTask?.cleanerId == authService.currentUser.id ||
                        report.cleanupTask?.cleanerId == 'd0000000-0000-0000-0000-000000000002') ...[
                      AppButton(
                        label: 'Lanjutkan Tugas Pembersihan Saya',
                        icon: Icons.cleaning_services_rounded,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.cleanerTaskDetail,
                            arguments: report.id,
                          );
                        },
                      ),
                    ] else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: BorderSide(color: Color(0xFFDC2626), width: 3.5),
                              top: BorderSide(color: Color(0xFFE2E8F0)),
                              right: BorderSide(color: Color(0xFFE2E8F0)),
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 18, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tugas ini telah dikunci untuk ${report.cleanerName ?? "relawan lain"}.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
