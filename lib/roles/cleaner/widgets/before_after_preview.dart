import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class BeforeAfterPreview extends StatelessWidget {
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final String beforeLocation;
  final String afterLocation;

  const BeforeAfterPreview({
    super.key,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
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
                      color: AppTheme.statusPendingBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SEBELUM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusPending,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: _buildPhoto(beforePhotoUrl),
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
                      color: AppTheme.statusCleanedBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SESUDAH BERSIH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusCleaned,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: _buildPhoto(afterPhotoUrl),
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
        child: Icon(Icons.broken_image_outlined, color: AppTheme.textMuted, size: 24),
      ),
    );
  }
}
