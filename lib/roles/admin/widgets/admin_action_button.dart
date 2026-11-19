import 'package:flutter/material.dart';

/// Warna/gaya tombol aksi pada tabel admin.
enum AdminButtonTone { primary, neutral, warning, success, danger }

/// Tombol aksi berbentuk pill (kapsul) dengan tinggi seragam,
/// dipakai di semua tabel admin agar tampilannya konsisten.
class AdminActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AdminButtonTone tone;
  final double minWidth;
  final double height;
  final bool expand;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AdminButtonTone.neutral,
    this.minWidth = 64,
    this.height = 34,
    this.expand = false,
  });

  ({Color bg, Color fg, Color border}) get _colors {
    switch (tone) {
      case AdminButtonTone.primary:
        return (bg: const Color(0xFF0F172A), fg: Colors.white, border: const Color(0xFF0F172A));
      case AdminButtonTone.warning:
        return (bg: const Color(0xFFFFFBEB), fg: const Color(0xFFB45309), border: const Color(0xFFFDE68A));
      case AdminButtonTone.success:
        return (bg: const Color(0xFFF0FDF4), fg: const Color(0xFF15803D), border: const Color(0xFFBBF7D0));
      case AdminButtonTone.danger:
        return (bg: const Color(0xFFFEF2F2), fg: const Color(0xFFB91C1C), border: const Color(0xFFFECACA));
      case AdminButtonTone.neutral:
        return (bg: const Color(0xFFF1F5F9), fg: const Color(0xFF0F172A), border: const Color(0xFFE2E8F0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: c.bg,
        foregroundColor: c.fg,
        minimumSize: Size(expand ? 0 : minWidth, height),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: StadiumBorder(side: BorderSide(color: c.border)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return expand ? SizedBox(width: double.infinity, height: height, child: button) : SizedBox(height: height, child: button);
  }
}
