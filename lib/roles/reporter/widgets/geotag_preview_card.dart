import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        ? const Color(0xFFDC2626)
        : (isAccuracyAcceptable ? const Color(0xFF0F766E) : const Color(0xFFD97706));

    final String statusLabel = !hasValidGps
        ? 'Lokasi Pesisir Tidak Terdeteksi'
        : (isAccuracyAcceptable ? 'Lokasi Pesisir Valid & Terverifikasi' : 'Lokasi Terdeteksi (Perlu Perhatian)');

    String formattedTime = '';
    if (hasValidGps && exifData.dateTimeOriginal != null) {
      try {
        formattedTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(exifData.dateTimeOriginal!);
      } catch (_) {
        formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(exifData.dateTimeOriginal!);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: statusColor, width: 3.5),
            top: const BorderSide(color: Color(0xFFE2E8F0)),
            right: const BorderSide(color: Color(0xFFE2E8F0)),
            bottom: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasValidGps ? Icons.verified_rounded : Icons.location_off_outlined,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (accuracy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '±${accuracy!.toStringAsFixed(0)}m',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasValidGps
                ? 'Titik lokasi pantai berhasil diverifikasi secara digital oleh sensor GPS perangkat.'
                : 'Foto tidak memiliki data lokasi pantai yang sah. Pastikan izin lokasi aktif.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          if (hasValidGps && exifData.dateTimeOriginal != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Waktu Foto: $formattedTime WIB',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
}
