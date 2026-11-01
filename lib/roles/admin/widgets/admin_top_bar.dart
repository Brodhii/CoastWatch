import 'package:flutter/material.dart';

class AdminTopBar extends StatelessWidget {
  final String breadcrumbParent;
  final String breadcrumbChild;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onOpenDrawer;

  const AdminTopBar({
    super.key,
    this.breadcrumbParent = 'Konsol',
    this.breadcrumbChild = 'Panel Kerja Lapangan',
    this.onSearch,
    this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    final isDesktop = width >= 1024;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Drawer menu toggle on mobile / tablet (Pure text button)
          if (onOpenDrawer != null) ...[
            OutlinedButton(
              onPressed: onOpenDrawer,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
          ],

          // Breadcrumbs (Clean text, no icons)
          Expanded(
            child: isMobile
                ? Text(
                    breadcrumbChild,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Row(
                    children: [
                      Text(
                        breadcrumbParent,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('/', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ),
                      Flexible(
                        child: Text(
                          breadcrumbChild,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),

          // Search input (Clean, text-only, no prefix icon)
          if (isDesktop) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: SizedBox(
                height: 34,
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    hintText: 'Cari ID tiket (CW-2026-...)',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Status indicator (Clean text border, no icon)
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Text(
                'Sinkron: Aktif',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Time label (Desktop)
          if (isDesktop) ...[
            const Text(
              '24 Okt 2026 (UTC+7)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
          ],

          // User text tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Admin BS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
