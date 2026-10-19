import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/report_service.dart';
import '../../../shared/status_badge.dart';

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

    final createdAtStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(report.createdAt);
    final photoTimeStr = report.exifDateTimeOriginal != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(report.exifDateTimeOriginal!)
        : 'Tidak tersimpan';

    return Scaffold(
      appBar: AppBar(
        title: Text(report.id),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photo Proof
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _buildPhoto(report.beforePhotoUrl),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.categoryName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rejection Notice if status is rejected
                  if (report.status == ReportStatus.rejected && report.rejectionReason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.statusRejectedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.statusRejected.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 16, color: AppTheme.statusRejected),
                              SizedBox(width: 6),
                              Text(
                                'Alasan Penolakan Admin:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusRejected,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.rejectionReason!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.statusRejected, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  const Text(
                    'Deskripsi Temuan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description.isNotEmpty ? report.description : 'Tidak ada deskripsi tambahan.',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Metadata Details
                  const Text(
                    'Metadata & Geotagging',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 8),

                  _buildMetaRow(Icons.place_outlined, 'Koordinat GPS', report.formattedCoordinates),
                  _buildMetaRow(
                    Icons.gps_fixed,
                    'Akurasi Sensor',
                    report.deviceLocationAccuracyM != null
                        ? '±${report.deviceLocationAccuracyM!.toStringAsFixed(1)}m'
                        : 'Akurasi tidak dicatat',
                  ),
                  _buildMetaRow(Icons.camera_alt_outlined, 'Waktu Foto', photoTimeStr),
                  _buildMetaRow(Icons.cloud_done_outlined, 'Waktu Diajukan', createdAtStr),

                  const SizedBox(height: 14),

                  // Mini Map
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(border: Border.all(color: AppTheme.border)),
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
                                width: 34,
                                height: 34,
                                child: const Icon(Icons.location_on, color: AppTheme.navy, size: 34),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cleanup Proof Section (if completed)
                  if (report.status == ReportStatus.cleaned && report.afterPhotoUrl != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Bukti Penanganan oleh Relawan Pembersih',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.statusCleaned),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildPhoto(report.afterPhotoUrl!),
                      ),
                    ),
                    if (report.cleanupTask?.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catatan Relawan: ${report.cleanupTask!.notes}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],

                  // Status History Timeline
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Riwayat Status & Audit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 12),

                  if (report.statusHistory.isEmpty)
                    const Text('Belum ada riwayat perubahan status.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
                  else
                    ...report.statusHistory.map((history) => _buildTimelineItem(history)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(dynamic history) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.teal,
              shape: BoxShape.circle,
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
                    Text(
                      history.toStatus.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(history.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                if (history.actorName != null)
                  Text(
                    'Oleh: ${history.actorName}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                if (history.reason != null)
                  Text(
                    history.reason!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.teal),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _fallback());
    } else if (url.isNotEmpty) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _fallback());
      }
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppTheme.background,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 36, color: AppTheme.textMuted),
      ),
    );
  }
}
