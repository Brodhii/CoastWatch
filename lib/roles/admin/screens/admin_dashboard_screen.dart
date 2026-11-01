import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';

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
        final pendingReports = reportService.reports
            .where((r) => r.status == ReportStatus.pendingReview)
            .take(4)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return ListView(
              padding: EdgeInsets.all(isSmall ? 14 : 20),
              children: [
                // 1. Tag & Header Title (Simple, minimal)
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
                    if (!isSmall) ...[
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data operasional telah diperbarui.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Perbarui Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Metric Cards (Card "Total Masuk" dihapus sesuai permintaan)
                _buildMetricCards(w),

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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                '14 Butuh Aksi',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                            if (w >= 700)
                              const Text(
                                'Wilayah: Pesisir Jabodetabek & Karawang',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                            const Text(
                              'Menampilkan 4 dari 14 laporan antrean',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                        child: _buildCategoryDistributionCard(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRecentDecisionsCard(),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCategoryDistributionCard(),
                      const SizedBox(height: 16),
                      _buildRecentDecisionsCard(),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // 4 METRIC CARDS (Card "Total Masuk" dihapus, desain simple putih)
  Widget _buildMetricCards(double w) {
    double cardWidth;
    if (w < 600) {
      cardWidth = (w - 10) / 2;
    } else {
      cardWidth = (w - 30) / 4;
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatCard(
          width: cardWidth,
          title: 'MENUNGGU VERIFIKASI',
          count: '14',
          unit: 'Laporan',
          footerText: '4 laporan >24 jam',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'TERVERIFIKASI',
          count: '128',
          unit: 'Laporan',
          footerText: 'Bukti digital valid',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'DITOLAK',
          count: '19',
          unit: 'Laporan',
          footerText: 'Alasan transparan',
        ),
        _buildStatCard(
          width: cardWidth,
          title: 'DITANDAI DUPLIKAT',
          count: '7',
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

  // DESKTOP TABLE
  Widget _buildDesktopTable(List<ReportModel> reports) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: const Row(
            children: [
              SizedBox(width: 50, child: Text('FOTO', style: _colHeaderStyle)),
              SizedBox(width: 90, child: Text('ID TIKET', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('KATEGORI & DESKRIPSI', style: _colHeaderStyle)),
              Expanded(flex: 2, child: Text('LOKASI PESISIR', style: _colHeaderStyle)),
              SizedBox(width: 120, child: Text('WAKTU', style: _colHeaderStyle)),
              SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('AKSI', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),

        _buildRow(
          reportId: 'CW-2026-00124',
          imageUrl: 'https://images.unsplash.com/photo-1618477388954-7852f32655ec?auto=format&fit=crop&w=300&q=80',
          category: 'Sampah Plastik',
          description: 'Akumulasi botol di intertidal',
          location: 'Muara Teluk Naga, Banten',
          time: '15 Okt 2024, 09:25',
        ),
        _buildRow(
          reportId: 'CW-2026-00125',
          imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=300&q=80',
          category: 'Limbah Cair / Indikasi Pencemaran',
          description: 'Lapisan minyak dan residu',
          location: 'Sungai Cisadane, Banten',
          time: '15 Okt 2024, 10:10',
        ),
        _buildRow(
          reportId: 'CW-2026-00126',
          imageUrl: 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?auto=format&fit=crop&w=300&q=80',
          category: 'Alat Tangkap & Limbah Perikanan',
          description: 'Jaring nilon terdampar',
          location: 'Tanjung Pasir, Tangerang',
          time: '15 Okt 2024, 11:05',
        ),
        _buildRow(
          reportId: 'CW-2026-00127',
          imageUrl: 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?auto=format&fit=crop&w=300&q=80',
          category: 'Sampah Rumah Tangga / Campuran',
          description: 'Tumpukan kantong plastik',
          location: 'Pesisir Sedari, Karawang',
          time: '15 Okt 2024, 11:40',
        ),
      ],
    );
  }

  Widget _buildRow({
    required String reportId,
    required String imageUrl,
    required String category,
    required String description,
    required String location,
    required String time,
  }) {
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
              child: Image.network(imageUrl, width: 40, height: 32, fit: BoxFit.cover),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              reportId,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => onNavigateToReview(reportId),
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

  // MOBILE CARDS
  Widget _buildMobileCardList(List<ReportModel> reports) {
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
                child: Image.network(
                  report.beforePhotoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(report.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        Text(
                          report.categoryName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.locationName ?? 'Pesisir Indonesia',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      maxLines: 2,
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

  // BOTTOM LEFT CARD: DISTRIBUSI KATEGORI
  Widget _buildCategoryDistributionCard() {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribusi Kategori Masuk',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                '168 Total',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildCategoryBar('Sampah Plastik', 0.48, '48% (81 lap.)'),
          const SizedBox(height: 8),
          _buildCategoryBar('Alat Tangkap & Limbah Perikanan', 0.22, '22% (37 lap.)'),
          const SizedBox(height: 8),
          _buildCategoryBar('Limbah Cair / Indikasi Pencemaran', 0.16, '16% (27 lap.)'),
          const SizedBox(height: 8),
          _buildCategoryBar('Sampah Rumah Tangga / Campuran', 0.10, '10% (17 lap.)'),
          const SizedBox(height: 8),
          _buildCategoryBar('Kerusakan Ekosistem Pesisir', 0.04, '4% (6 lap.)'),
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
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
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

  // BOTTOM RIGHT CARD: LOG KEPUTUSAN TERBARU
  Widget _buildRecentDecisionsCard() {
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

          _buildDecisionItem(
            statusTag: 'DISETUJUI',
            title: 'Laporan CW-2026-00120 disetujui',
            time: '35 mnt lalu',
            decisionText: 'Bukti digital valid diverifikasi oleh Admin Budi.',
          ),
          const SizedBox(height: 8),

          _buildDecisionItem(
            statusTag: 'DITOLAK',
            title: 'Laporan CW-2026-00119 ditolak',
            time: '1 jam lalu',
            decisionText: 'Objek sampah tidak fokus & metadata tidak konsisten.',
            isDanger: true,
          ),
          const SizedBox(height: 8),

          _buildDecisionItem(
            statusTag: 'DUPLIKAT',
            title: 'Laporan CW-2026-00118 ditandai duplikat',
            time: '2 jam lalu',
            decisionText: 'Ditautkan ke tiket utama #CW-2026-00115 (radius <8m).',
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionItem({
    required String statusTag,
    required String title,
    required String time,
    required String decisionText,
    bool isDanger = false,
  }) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      statusTag,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                ],
              ),
              Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 3),
          Text(decisionText, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.5,
  );
}
