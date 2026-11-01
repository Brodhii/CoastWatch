import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/report_service.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback? onLogout;
  final double? width;
  final bool isDrawer;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelectIndex,
    this.onLogout,
    this.width,
    this.isDrawer = false,
  });

  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarActiveBg = Color(0xFF1E293B);
  static const Color sidebarBorder = Color(0xFF1E293B);
  static const Color sidebarText = Color(0xFFE2E8F0);
  static const Color sidebarTextMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();

    final content = Container(
      width: width ?? (isDrawer ? double.infinity : 250),
      decoration: const BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Branding: Clean Typographic Monogram
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Text(
                    'CW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CoastWatch',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'OPERATIONAL GIS',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDrawer)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: sidebarTextMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('[Tutup]', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          const Divider(color: sidebarBorder, height: 1),

          // 2. Navigation Header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'NAVIGASI OPERASIONAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),

          // 3. Navigation List (Pure text, zero icons)
          Expanded(
            child: ListenableBuilder(
              listenable: reportService,
              builder: (context, _) {
                final pendingCount = reportService.reports.where((r) => r.status == ReportStatus.pendingReview).length;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Ringkasan',
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Verifikasi Laporan',
                      badgeCount: pendingCount > 0 ? pendingCount : 12,
                    ),
                    _buildNavItem(
                      index: 2,
                      label: 'Peta Laporan',
                    ),
                    _buildNavItem(
                      index: 3,
                      label: 'Kategori',
                    ),
                    _buildNavItem(
                      index: 4,
                      label: 'Pengguna',
                    ),
                    _buildNavItem(
                      index: 5,
                      label: 'Riwayat Aktivitas',
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(color: sidebarBorder, height: 1),

          // 4. Budi Santoso Profile Card (Tanda online dihapus, tombol Keluar diperbarui rapi)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: sidebarBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Text(
                      'BS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budi Santoso',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Admin Operasional',
                          style: TextStyle(fontSize: 9, color: sidebarTextMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDrawer) {
      return SafeArea(
        bottom: false,
        child: content,
      );
    }
    return content;
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: isSelected ? sidebarActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onSelectIndex(index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? const Border(left: BorderSide(color: Colors.white, width: 3))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : sidebarTextMuted,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
