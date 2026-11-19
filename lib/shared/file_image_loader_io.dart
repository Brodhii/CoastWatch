import 'dart:io';
import 'package:flutter/widgets.dart';

/// Implementasi untuk platform Native (Android, iOS, Windows, macOS, Linux).
/// Menggunakan `dart:io` File secara aman.
Widget? buildPlatformFileImage({
  required String filePath,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  try {
    final file = File(filePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  } catch (_) {}
  return null;
}

