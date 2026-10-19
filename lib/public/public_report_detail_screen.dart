import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/report_service.dart';
import '../shared/status_badge.dart';

class PublicReportDetailScreen extends StatelessWidget {
  final String reportId;

  const PublicReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final report = reportService.getReportById(reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(
          child: Text('Laporan tidak ditemukan.'),
        ),
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
            // 1. Large Main Proof Photo (Desain.md Section 15.8)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _buildMainPhoto(report.beforePhotoUrl),
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

                  // Description
                  const Text(
                    'Deskripsi Temuan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description.isNotEmpty ? report.description : 'Tidak ada deskripsi tambahan.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Geotag & Location Metadata
                  const Text(
                    'Verifikasi Lokasi & Geotag EXIF',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildMetaRow(
                    icon: Icons.place_outlined,
                    label: 'Koordinat Resmi EXIF',
                    value: report.formattedCoordinates,
                  ),
                  _buildMetaRow(
                    icon: Icons.gps_fixed,
                    label: 'Akurasi Sensor Perangkat',
                    value: report.deviceLocationAccuracyM != null
                        ? '±${report.deviceLocationAccuracyM!.toStringAsFixed(1)} meter'
                        : 'Akurasi tidak dicatat',
                  ),
                  _buildMetaRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Waktu Pengambilan Foto',
                    value: photoTimeStr,
                  ),
                  _buildMetaRow(
                    icon: Icons.cloud_done_outlined,
                    label: 'Waktu Diterima Server',
                    value: createdAtStr,
                  ),

                  const SizedBox(height: 16),

                  // Mini Map Context (Section 15.6 point 4: pin cannot be moved)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(report.latitude, report.longitude),
                          initialZoom: 14.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none, // Static non-draggable mini preview
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
                                point: LatLng(report.latitude, report.longitude),
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppTheme.navy,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '*Pin lokasi mini map bersifat baca-saja berdasarkan ekstraksi metadata EXIF resmi.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),

                  const SizedBox(height: 20),

                  // Context Notice Card (Desain.md Section 15.8)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.skyBlue.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.navy),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status Terverifikasi menyatakan bukti foto dan tag GPS telah lulus verifikasi digital sistem CoastWatch. Data identitas pelapor dirahasiakan untuk privasi.',
                            style: TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.teal),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPhoto(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
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
        child: Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.textMuted),
      ),
    );
  }
}
