import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/admin_audit_log_model.dart';
import '../../../services/report_service.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  final ReportService _reportService = ReportService();
  String _searchQuery = '';

  List<AdminAuditLogModel> _getFilteredLogs(List<AdminAuditLogModel> allLogs) {
    if (_searchQuery.trim().isEmpty) return allLogs;
    final q = _searchQuery.trim().toLowerCase();
    return allLogs.where((l) =>
      l.targetId.toLowerCase().contains(q) ||
      l.adminName.toLowerCase().contains(q) ||
      l.adminRole.toLowerCase().contains(q) ||
      l.actionType.toLowerCase().contains(q) ||
      l.targetLocation.toLowerCase().contains(q) ||
      l.summary.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final allLogs = _reportService.auditLogs;
        final logs = _getFilteredLogs(allLogs);

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return ListView(
              padding: EdgeInsets.all(isSmall ? 14 : 20),
              children: [
                // 1. Tag & Header Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUDIT LOG KONSOL • BACA-SAJA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Riwayat Aktivitas & Audit',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Catatan kronologis seluruh keputusan verifikasi dan tindakan administratif staf Admin.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (!isSmall)
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Laporan audit diekspor ke CSV.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Ekspor Log (CSV)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. 3 Stat Cards
                _buildStatCards(w, allLogs),

                const SizedBox(height: 16),

                // 3. Search Bar
                _buildFilterControls(isDesktop),

                const SizedBox(height: 14),

                // 4. Audit Table (Desktop) vs Mobile Audit Cards
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (isDesktop)
                        _buildDesktopAuditTable(logs)
                      else
                        _buildMobileAuditCards(logs),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      // Pagination / Summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menampilkan ${logs.length} entri riwayat aktivitas • Sinkron UTC+7',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(3)),
                              child: const Text('1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 5. Policy Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Integritas Audit CoastWatch',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jejak audit bersifat permanen dan tidak dapat diubah atau dihapus untuk menjamin akuntabilitas penanganan laporan lingkungan pesisir.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCards(double w, List<AdminAuditLogModel> allLogs) {
    final totalEntries = allLogs.length;
    final verifiedCount = allLogs.where((l) => l.actionType.toUpperCase().contains('VERIFIKASI')).length;
    final rejectedCount = allLogs.where((l) => l.actionType.toUpperCase().contains('TOLAK') || l.actionType.toUpperCase().contains('DUPLIKAT')).length;
    final now = DateTime.now();
    final todayCount = allLogs.where((l) => l.timestamp.year == now.year && l.timestamp.month == now.month && l.timestamp.day == now.day).length;

    final card1 = _buildStatCard(
      title: 'TOTAL AKTIVITAS',
      count: '$totalEntries',
      sub: '+$todayCount tercatat hari ini',
    );
    final card2 = _buildStatCard(
      title: 'VERIFIKASI & PERSETUJUAN',
      count: '$verifiedCount',
      sub: 'Keputusan validasi aktif',
    );
    final card3 = _buildStatCard(
      title: 'TOLAK & DUPLIKAT',
      count: '$rejectedCount',
      sub: 'Penyaringan laporan invalid',
    );

    // Desktop/Tablet: tepat 3 kartu ke samping dalam 1 baris simetris
    if (w >= 700) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 10),
          Expanded(child: card2),
          const SizedBox(width: 10),
          Expanded(child: card3),
        ],
      );
    } else {
      // Mobile: tersusun rapi vertikal
      return Column(
        children: [
          card1,
          const SizedBox(height: 10),
          card2,
          const SizedBox(height: 10),
          card3,
        ],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFilterControls(bool isDesktop) {
    final search = SizedBox(
      height: 36,
      child: TextField(
        style: const TextStyle(fontSize: 12),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          hintText: 'Cari ID Laporan (#CW-...), Aktor, Tindakan, atau Wilayah...',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        ),
      ),
    );

    return search;
  }

  // DESKTOP TABLE
  Widget _buildDesktopAuditTable(List<AdminAuditLogModel> logs) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, size: 36, color: Color(0xFF94A3B8)),
              SizedBox(height: 8),
              Text(
                'Belum ada catatan aktivitas yang sesuai dengan kriteria.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: const Row(
            children: [
              SizedBox(width: 120, child: Text('WAKTU (WIB)', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('AKTOR / PENGGUNA', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('JENIS TINDAKAN', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('LOKASI', style: _colHeaderStyle)),
              Expanded(flex: 5, child: Text('RINGKASAN AKTIVITAS & CATATAN', style: _colHeaderStyle)),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        ...logs.map((log) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waktu
                SizedBox(
                  width: 120,
                  child: Text(
                    DateFormat('dd MMM yyyy\nHH:mm \'WIB\'', 'id_ID').format(log.timestamp),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
                  ),
                ),

                // Aktor / Staf
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.adminName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Text(log.adminRole, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                    ],
                  ),
                ),

                // JENIS TINDAKAN: Refined subtle badge
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildActionTypeBadge(log.actionType),
                  ),
                ),

                // Lokasi
                Expanded(
                  flex: 3,
                  child: Text(
                    log.targetLocation.isNotEmpty ? log.targetLocation : '-',
                    style: TextStyle(
                      fontSize: 11,
                      color: (log.targetLocation == '-' || log.targetLocation.isEmpty)
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                      fontWeight: (log.targetLocation == '-' || log.targetLocation.isEmpty)
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),

                // Ringkasan
                Expanded(
                  flex: 5,
                  child: Text(log.summary, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), height: 1.35)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // REFINED ACTION BADGE (Clean, subtle, professional)
  Widget _buildActionTypeBadge(String rawAction) {
    Color textColor;
    Color borderColor;
    Color bgColor;

    final isRejected = rawAction.contains('TOLAK');
    final isVerified = rawAction.contains('VERIFIKASI');
    final isDuplicate = rawAction.contains('DUPLIKAT');
    final isAccount = rawAction.contains('AKUN');

    if (isRejected) {
      textColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFCA5A5);
      bgColor = const Color(0xFFFEF2F2);
    } else if (isVerified) {
      textColor = const Color(0xFF0F172A);
      borderColor = const Color(0xFFCBD5E1);
      bgColor = const Color(0xFFF8FAFC);
    } else if (isDuplicate) {
      textColor = const Color(0xFF475569);
      borderColor = const Color(0xFFE2E8F0);
      bgColor = const Color(0xFFF8FAFC);
    } else if (isAccount) {
      textColor = const Color(0xFFB45309);
      borderColor = const Color(0xFFFDE68A);
      bgColor = const Color(0xFFFFFBEB);
    } else {
      textColor = const Color(0xFF0F172A);
      borderColor = const Color(0xFFCBD5E1);
      bgColor = const Color(0xFFF8FAFC);
    }

    // Convert ALL CAPS to Clean Title Case
    final words = rawAction.split(' ');
    final cleanText = words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        cleanText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMobileAuditCards(List<AdminAuditLogModel> logs) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada catatan aktivitas.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ),
      );
    }

    return Column(
      children: logs.map((log) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionTypeBadge(log.actionType),
                  Text(
                    DateFormat("dd MMM yyyy, HH:mm 'WIB'", 'id_ID').format(log.timestamp),
                    style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                log.targetLocation.isNotEmpty ? log.targetLocation : '-',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: (log.targetLocation == '-' || log.targetLocation.isEmpty) ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text('Oleh: ${log.adminName} (${log.adminRole})', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              const SizedBox(height: 3),
              Text(log.summary, style: const TextStyle(fontSize: 10, color: Color(0xFF334155), height: 1.3)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.5,
  );
}
