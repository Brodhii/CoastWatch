import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../services/exif_service.dart';

class GeotagPreviewCard extends StatelessWidget {
  final ExifDataResult exifData;
  final double? accuracy;

  const GeotagPreviewCard({
    super.key,
    required this.exifData,
    this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidGps = exifData.isValid;
    final bool isAccuracyAcceptable = accuracy == null || accuracy! <= 50.0;

    final Color statusColor = !hasValidGps
        ? AppTheme.statusRejected
        : (isAccuracyAcceptable ? AppTheme.statusCleaned : AppTheme.statusPending);

    final Color bgColor = !hasValidGps
        ? AppTheme.statusRejectedBg
        : (isAccuracyAcceptable ? AppTheme.statusCleanedBg : AppTheme.statusPendingBg);

    final IconData statusIcon = !hasValidGps
        ? Icons.cancel_outlined
        : (isAccuracyAcceptable ? Icons.check_circle_outline : Icons.warning_amber_rounded);

    final String statusLabel = !hasValidGps
        ? 'GPS Tidak Ditemukan'
        : (isAccuracyAcceptable ? 'Geotag Sah & Akurat' : 'Geotag Perlu Perhatian');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exifData.statusMessage,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              height: 1.3,
            ),
          ),
          if (hasValidGps) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.my_location, size: 14, color: AppTheme.navy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    exifData.formattedCoordinates,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
                if (accuracy != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '±${accuracy!.toStringAsFixed(0)}m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),
            if (exifData.dateTimeOriginal != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(exifData.dateTimeOriginal!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
