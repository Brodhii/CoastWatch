import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../shared/safe_app_image.dart';

class BeforeAfterPreview extends StatelessWidget {
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final Uint8List? afterPhotoBytes;
  final String beforeLocation;
  final String afterLocation;

  const BeforeAfterPreview({
    super.key,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    this.afterPhotoBytes,
    required this.beforeLocation,
    required this.afterLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perbandingan Sebelum & Sesudah Pembersihan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Before Photo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'SEBELUM BERSIH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: SafeAppImage(
                        imageUrl: beforePhotoUrl,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beforeLocation,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // After Photo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Text(
                      'SESUDAH BERSIH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: SafeAppImage(
                        imageBytes: afterPhotoBytes,
                        imageUrl: afterPhotoBytes != null ? null : afterPhotoUrl,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    afterLocation,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
