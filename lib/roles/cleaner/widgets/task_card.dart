import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../models/report_model.dart';
import '../../../shared/status_badge.dart';

class TaskCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  final bool isAvailableTask;

  const TaskCard({
    super.key,
    required this.report,
    required this.onTap,
    this.isAvailableTask = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(report.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildThumbnail(report.beforePhotoUrl),
              ),
            ),
            const SizedBox(width: 12),
            // Info
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
                      StatusBadge(status: report.status, isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.locationName ?? report.formattedCoordinates,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terverifikasi: $formattedDate',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      if (isAvailableTask)
                        const Text(
                          'Tersedia Ditangani →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.teal,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String url) {
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
        child: Icon(Icons.image_not_supported_outlined, color: AppTheme.textMuted, size: 24),
      ),
    );
  }
}
