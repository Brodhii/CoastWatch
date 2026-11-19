import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'file_image_loader.dart';

/// Komponen render gambar universal yang 100% aman untuk Flutter Web, Android, iOS & Desktop.
/// Mencegah konflik kompilasi dart:io vs dart:html pada browser (Web)
/// serta menangani URL internet, Blob, Base64 data-uri, maupun berkas lokal.
class SafeAppImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  const SafeAppImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 1. Raw Bytes (In-Memory)
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      content = Image.memory(
        imageBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 2. String URL / Path
    else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final url = imageUrl!.trim();

      // a. Network URL atau Blob URL (didukung browser & native)
      if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:')) {
        content = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppTheme.background,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.teal),
                ),
              ),
            );
          },
        );
      }
      // b. Data URI (Base64)
      else if (url.startsWith('data:image')) {
        try {
          final commaIdx = url.indexOf(',');
          final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
          final bytes = base64Decode(base64Str);
          content = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        } catch (_) {
          content = _buildFallback();
        }
      }
      // c. Berkas Lokal (Mobile / Desktop via conditional platform loader)
      else {
        final localImageWidget = buildPlatformFileImage(
          filePath: url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );

        content = localImageWidget ?? _buildFallback();
      }
    }
    // 3. Kosong / Null
    else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallback() {
    if (fallback != null) return fallback!;

    return Container(
      width: width,
      height: height,
      color: AppTheme.background,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textMuted,
        size: 24,
      ),
    );
  }
}
