import 'package:flutter/widgets.dart';

/// Implementasi fallback untuk platform Web.
/// Pada Web, tidak ada akses berkas lokal via File() sehingga mengembalikan null.
Widget? buildPlatformFileImage({
  required String filePath,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return null;
}

