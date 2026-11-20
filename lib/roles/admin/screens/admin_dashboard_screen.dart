import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/admin_audit_log_model.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../../../shared/safe_app_image.dart';

class AdminDashboardScreen extends StatelessWidget {
  final ValueChanged<String> onNavigateToReview;
  final VoidCallback onNavigateToQueue;
  final VoidCallback onNavigateToAuditLogs;

  const AdminDashboardScreen({
    super.key,
    required this.onNavigateToReview,
    required this.onNavigateToQueue,
    required this.onNavigateToAuditLogs,
  });

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();

    return ListenableBuilder(
      listenable: reportService,
      builder: (context, _) {
        final totalQueueReports = reportService.reports
            .where((r) => r.status == ReportStatus.pendingReview || r.status == ReportStatus.pendingCleanupReview)
            .toList();
        final pendingReports = totalQueueReports.take(4).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return RefreshIndicator(
              color: const Color(0xFF0F172A),
              onRefresh: () async {
                await reportService.refreshFromCloud();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Text(
                              'Ringkasan Operasional',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pantau laporan masuk dan tindak lanjut verifikasi bukti lingkungan pesisir.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Metric Cards
                  _buildMetricCards(w, reportService),

                const SizedBox(height: 20),

                // 3. Section: Antrean Perlu Ditinjau Segera
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Text(
                              'Antrean Perlu Ditinjau Segera',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (totalQueueReports.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${totalQueueReports.length} Butuh Aksi',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            const Spacer(),
                            if (w >= 700)
                              Text(
                                totalQueueReports.isEmpty
                                    ? 'Semua laporan telah ditinjau'
                                    : '${totalQueueReports.length} laporan menunggu aksi',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      // Table (Desktop) or Card List (Mobile)
                      if (isDesktop)
                        _buildDesktopTable(pendingReports)
                      else
                        _buildMobileCardList(pendingReports),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalQueueReports.isEmpty
                                  ? 'Tidak ada laporan dalam antrean saat ini'
                                  : 'Menampilkan ${pendingReports.length} dari ${totalQueueReports.length} laporan antrean',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            InkWell(
                              onTap: onNavigateToQueue,
                              child: const Text(
                                'Buka Antrean Verifikasi →',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Two Bottom Sections: Category Distribution & Recent Decisions
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCategoryDistributionCard(reportService),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRecentDecisionsCard(reportService),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCategoryDistributionCard(reportService),
                      const SizedBox(height: 16),
                      _buildRecentDecisionsCard(reportService),
                    ],
                  ),
              ],
            ),
          );
        },
        );
      },
    );
  }

  // 4 METRIC CARDS — fully dynamic from Supabase
  Widget _buildMetricCards(double w, ReportService reportService) {
    double cardWidth;
    if (w < 600) {
      cardWidth = (w - 10) / 2;
    } else {
      cardWidth = (w - 30) / 4;
    }

    final pendingCount = reportService.reports.where((r) => r.status == ReportStatus.pendingReview).length;
    final verifiedCount = reportService.reports.where((r) => r.status == ReportStatus.verified || r.status == ReportStatus.inProgress || r.status == ReportStatus.cleaned).length;
    final rejectedCount = reportService.reports.where((r) => r.status == ReportStatus.rejected).length;
    final duplicateCount = reportService.reports.where((r) => r.status == ReportStatus.duplicate).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatCard(
          width: cardWidth,
          title: 'MENUNGGU VERIFIKASI',
          count: '$pendingCount',
          unit: 'Laporan',
          footerText: pendingCount > 0 ? '$pendingCount laporan antrean' : 'Antrean bersih',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'TERVERIFIKASI',
          count: '$verifiedCount',
          unit: 'Laporan',
          footerText: 'Bukti GIS valid',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'DITOLAK',
          count: '$rejectedCount',
          unit: 'Laporan',
          footerText: 'Alasan transparan',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'DITANDAI DUPLIKAT',
          count: '$duplicateCount',
          unit: 'Laporan',
          footerText: 'Radius klaster identik',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String count,
    required String unit,
    required String footerText,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footerText,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // DESKTOP TABLE — fully dynamic
  Widget _buildDesktopTable(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Tidak ada laporan dalam antrean.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
              SizedBox(width: 50, child: Text('FOTO', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('KATEGORI & DESKRIPSI', style: _colHeaderStyle)),
              Expanded(flex: 2, child: Text('LOKASI PESISIR', style: _colHeaderStyle)),
              SizedBox(width: 130, child: Text('WAKTU', style: _colHeaderStyle)),
              SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('AKSI', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        ...reports.map((report) => _buildDynamicRow(report)),
      ],
    );
  }

  Widget _buildDynamicRow(ReportModel report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SafeAppImage(imageUrl: report.beforePhotoUrl, width: 40, height: 32, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.categoryName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Text(
                  report.description.isEmpty ? '—' : report.description,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.locationName ?? '—',
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(report.createdAt),
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => onNavigateToReview(report.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Periksa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MOBILE CARDS — fully dynamic
  Widget _buildMobileCardList(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Tidak ada laporan dalam antrean.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ),
      );
    }
    return Column(
      children: reports.map((report) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SafeAppImage(imageUrl: report.beforePhotoUrl, width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM', 'id_ID').format(report.createdAt),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.locationName ?? '—',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description.isEmpty ? '—' : report.description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onNavigateToReview(report.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Periksa Bukti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // BOTTOM LEFT CARD: DISTRIBUSI KATEGORI — fully dynamic
  Widget _buildCategoryDistributionCard(ReportService reportService) {
    final total = reportService.reports.length;

    // Group by category from live reports
    final Map<String, int> catCount = {};
    for (final r in reportService.reports) {
      catCount[r.categoryName] = (catCount[r.categoryName] ?? 0) + 1;
    }
    // Sort descending by count, take top 5
    final sorted = catCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distribusi Kategori Masuk',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                '$total Total',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (total == 0)
            const Text('Belum ada laporan masuk.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          else
            ...top5.expand((entry) {
              final ratio = total > 0 ? entry.value / total : 0.0;
              final pct = (ratio * 100).round();
              return [
                _buildCategoryBar(entry.key, ratio, '$pct% (${entry.value} lap.)'),
                const SizedBox(height: 8),
              ];
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String label, double ratio, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(percent, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // BOTTOM RIGHT CARD: LOG KEPUTUSAN TERBARU — fully dynamic from auditLogs
  Widget _buildRecentDecisionsCard(ReportService reportService) {
    final recentLogs = reportService.auditLogs.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Log Keputusan Admin Terbaru',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              InkWell(
                onTap: onNavigateToAuditLogs,
                child: const Text(
                  'Riwayat Lengkap →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentLogs.isEmpty)
            const Text('Belum ada log keputusan.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          else
            ...recentLogs.expand((log) => [
              _buildDecisionItem(log: log),
              const SizedBox(height: 8),
            ]),
        ],
      ),
    );
  }

  Widget _buildDecisionItem({required AdminAuditLogModel log}) {
    final isDanger = log.actionType.contains('TOLAK') || log.actionType.contains('NONAKTIF');
    final isDuplicate = log.actionType.contains('DUPLIKAT');
    final tagColor = isDanger
        ? const Color(0xFFDC2626)
        : (isDuplicate ? const Color(0xFF7C3AED) : const Color(0xFF0F172A));
    final timeAgo = _timeAgo(log.timestamp);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        log.actionType,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${log.targetId} · ${log.adminName}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(timeAgo, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            log.summary,
            style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.5,
  );
}
