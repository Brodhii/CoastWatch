import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';
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
  bool _isClaiming = false;

  Future<void> _claimTask(ReportModel report) async {
    setState(() {
      _isClaiming = true;
    });

    try {
      final success = await _reportService.claimTask(report.id);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diambil! Status laporan berubah menjadi Sedang Ditangani.'),
            backgroundColor: AppTheme.navy,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil tugas: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
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
        final isClaimedByMe = report.cleanupTask?.cleanerId == currentUserId;
        final isAvailableToClaim = report.isAvailableForCleanup;
        final isCompleted = report.status == ReportStatus.cleaned;

        return Scaffold(
          appBar: AppBar(
            title: Text('Tugas ${report.id}'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Initial Photo Proof
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

                      // Location & Description
                      const Text(
                        'Deskripsi Temuan Lapangan',
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

                      // Location & Geotag details
                      const Text(
                        'Koordinat Titik Pembersihan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
                      ),
                      const SizedBox(height: 8),

                      _buildMetaRow(Icons.place_outlined, 'Koordinat Laporan Awal', report.formattedCoordinates),
                      if (report.locationName != null)
                        _buildMetaRow(Icons.map_outlined, 'Lokasi', report.locationName!),

                      const SizedBox(height: 12),

                      // Mini Map Preview
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

                      // If completed: show BeforeAfterPreview
                      if (isCompleted && report.afterPhotoUrl != null) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        BeforeAfterPreview(
                          beforePhotoUrl: report.beforePhotoUrl,
                          afterPhotoUrl: report.afterPhotoUrl!,
                          beforeLocation: report.locationName ?? report.formattedCoordinates,
                          afterLocation: report.cleanupTask?.cleanupLat != null
                              ? '${report.cleanupTask!.cleanupLat!.toStringAsFixed(4)}°, ${report.cleanupTask!.cleanupLng!.toStringAsFixed(4)}°'
                              : report.formattedCoordinates,
                        ),
                        if (report.cleanupTask?.notes != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Catatan Pembersihan: ${report.cleanupTask!.notes}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 24),

                      // Dynamic Action Button based on state
                      if (isAvailableToClaim) ...[
                        AppButton(
                          label: 'Ambil Tugas Pembersihan Ini',
                          onPressed: _isClaiming ? null : () => _claimTask(report),
                          isLoading: _isClaiming,
                          icon: Icons.handyman,
                          variant: AppButtonVariant.primary,
                        ),
                      ] else if (isClaimedByMe && report.status == ReportStatus.inProgress) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.statusInProgressBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.statusInProgress.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppTheme.statusInProgress),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tugas ini sedang Anda kerjakan. Setelah selesai di lokasi, unggah foto bukti sesudah pembersihan ber-geotag.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.statusInProgress, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppButton(
                          label: 'Unggah Bukti Sesudah Pembersihan',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.cleanupProof,
                              arguments: report.id,
                            );
                          },
                          icon: Icons.camera_alt,
                          variant: AppButtonVariant.secondary,
                        ),
                      ] else if (isCompleted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.statusCleanedBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, color: AppTheme.statusCleaned, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tugas Ini Telah Selesai Dibersihkan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusCleaned,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
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

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.teal),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
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
