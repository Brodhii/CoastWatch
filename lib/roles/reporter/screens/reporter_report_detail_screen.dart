import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../services/report_service.dart';
import '../../../shared/safe_app_image.dart';
import '../../../shared/status_badge.dart';
import '../../cleaner/widgets/before_after_preview.dart';

class ReporterReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReporterReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final report = reportService.getReportById(reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(child: Text('Laporan tidak ditemukan.')),
      );
    }

    final photoTimeStr = report.exifDateTimeOriginal != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(report.exifDateTimeOriginal!)
        : DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(report.createdAt);

    final regionName = report.locationName != null && report.locationName!.isNotEmpty
        ? report.locationName!
        : 'Kawasan Pesisir Pantai Batam';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Laporan Saya'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Proof
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
                  // Main Information Card
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
                            'Deskripsi Temuan',
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

                  // Rejection Notice if rejected (Clean white card with solid red accent border)
                  if (report.status == ReportStatus.rejected && report.rejectionReason != null) ...[
                    const SizedBox(height: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text(
                                  'Alasan Penolakan dari Admin:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              report.rejectionReason!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // In-Progress Notice (Clean white card with solid blue accent border)
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
                                    'Sedang Dikerjakan Relawan',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Laporan Anda saat ini sedang dibersihkan oleh ${report.cleanerName ?? "relawan pembersih pesisir CoastWatch"}.',
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

                  // Pending Cleanup Review Notice (Clean white card with solid purple accent border)
                  if (report.status == ReportStatus.pendingCleanupReview) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: Color(0xFF7C3AED), width: 3.5),
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                            right: BorderSide(color: Color(0xFFE2E8F0)),
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fact_check_outlined, color: Color(0xFF7C3AED), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pembersihan Selesai — Menunggu Validasi Admin',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Relawan (${report.cleanerName ?? "Relawan"}) telah mengunggah bukti pembersihan dan sedang menunggu pengesahan akhir.',
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

                  // Cleaned Notice & Before-After Comparison (Clean white card with solid green accent border)
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
                                'Laporan Telah Selesai Ditangani!',
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

                  const SizedBox(height: 16),

                  // Map Preview Card
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

                  // Status History Timeline
                  if (report.statusHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
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
                          const Text(
                            'Riwayat Pembaruan Status',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 12),
                          ...report.statusHistory.map((item) {
                            final timeStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.createdAt);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F766E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.toStatus.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          '$timeStr • ${item.actorName}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                        if (item.reason != null && item.reason!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              item.reason!,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
