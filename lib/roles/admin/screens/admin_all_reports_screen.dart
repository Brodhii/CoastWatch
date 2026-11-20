import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../../../shared/safe_app_image.dart';
import '../../../shared/status_badge.dart';

class AdminAllReportsScreen extends StatefulWidget {
  final ValueChanged<String> onNavigateToReview;

  const AdminAllReportsScreen({
    super.key,
    required this.onNavigateToReview,
  });

  @override
  State<AdminAllReportsScreen> createState() => _AdminAllReportsScreenState();
}

class _AdminAllReportsScreenState extends State<AdminAllReportsScreen> {
  final ReportService _reportService = ReportService();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';

  void _confirmDeleteReport(ReportModel report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hapus Laporan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus laporan "${report.categoryName}" di ${report.locationName ?? 'wilayah pesisir'} secara permanen?',
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Data laporan dan media foto akan dihapus permanen dari server Supabase.',
                style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _reportService.deleteReport(report.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Laporan berhasil dihapus.' : 'Gagal menghapus laporan.'),
                    backgroundColor: success ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
                  ),
                );
              }
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final allReports = _reportService.reports;
        final filteredReports = _filteredReports;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return RefreshIndicator(
              color: const Color(0xFF0F172A),
              onRefresh: () async {
                await _reportService.refreshFromCloud();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isSmall ? 14 : 20),
                children: [
                  // 1. Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semua Laporan Pesisir',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total ${allReports.length} laporan pesisir tersinkronisasi. Kelola data, pantau proses tindak lanjut, dan audit seluruh status.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Filter Bar
                  _buildFilterBar(isDesktop),

                  const SizedBox(height: 14),

                  // 3. Table / Card List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        if (isDesktop)
                          _buildDesktopTable(filteredReports)
                        else
                          _buildMobileList(filteredReports, isTablet: w >= 640),

                        const Divider(color: Color(0xFFE2E8F0), height: 1),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                filteredReports.isEmpty
                                    ? 'Tidak ada laporan yang sesuai dengan filter'
                                    : 'Menampilkan ${filteredReports.length} dari ${allReports.length} laporan',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              if (filteredReports.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Catatan: Admin memiliki hak untuk meninjau kembali status laporan, mengesahkan aksi bersih relawan, atau menolak laporan yang tidak valid kapan saja.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterBar(bool isDesktop) {
    final searchBox = SizedBox(
      height: 36,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          hintText: 'Cari deskripsi, lokasi, kategori...',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        ),
      ),
    );

    final statusDropdown = _buildDropdown(
      value: _selectedStatus,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Status')),
        DropdownMenuItem(value: 'pending_review', child: Text('Menunggu Verifikasi')),
        DropdownMenuItem(value: 'verified', child: Text('Terverifikasi (Peta GIS)')),
        DropdownMenuItem(value: 'in_progress', child: Text('Sedang Dibersihkan Relawan')),
        DropdownMenuItem(value: 'pending_cleanup', child: Text('Menunggu Validasi Bersih')),
        DropdownMenuItem(value: 'cleaned', child: Text('Selesai Bersih')),
        DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
        DropdownMenuItem(value: 'duplicate', child: Text('Duplikat')),
      ],
      onChanged: (v) => setState(() => _selectedStatus = v ?? 'all'),
    );

    final categoryDropdown = _buildDropdown(
      value: _selectedCategory,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
        DropdownMenuItem(value: 'sampah plastik', child: Text('Sampah Plastik')),
        DropdownMenuItem(value: 'limbah cair', child: Text('Limbah Cair / Minyak')),
        DropdownMenuItem(value: 'alat tangkap', child: Text('Alat Tangkap & Jaring')),
        DropdownMenuItem(value: 'sampah rumah tangga', child: Text('Sampah Rumah Tangga')),
        DropdownMenuItem(value: 'kerusakan ekosistem', child: Text('Kerusakan Ekosistem')),
        DropdownMenuItem(value: 'sampah organik', child: Text('Sampah Organik')),
        DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
      ],
      onChanged: (v) => setState(() => _selectedCategory = v ?? 'all'),
    );

    final resetButton = TextButton(
      onPressed: () {
        setState(() {
          _searchQuery = '';
          _selectedStatus = 'all';
          _selectedCategory = 'all';
        });
      },
      child: const Text('Reset Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
    );

    if (isDesktop) {
      return Row(
        children: [
          SizedBox(width: 220, child: searchBox),
          const SizedBox(width: 8),
          statusDropdown,
          const SizedBox(width: 8),
          categoryDropdown,
          const SizedBox(width: 8),
          resetButton,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchBox,
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                statusDropdown,
                const SizedBox(width: 8),
                categoryDropdown,
                const SizedBox(width: 8),
                resetButton,
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Tidak ada laporan yang ditemukan.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
              SizedBox(width: 44, child: Text('FOTO', style: _colHeaderStyle)),
              SizedBox(width: 100, child: Text('TANGGAL', style: _colHeaderStyle)),
              SizedBox(width: 155, child: Text('STATUS', style: _colHeaderStyle)),
              SizedBox(width: 165, child: Text('KATEGORI TEMUAN', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('RINGKASAN DESKRIPSI', style: _colHeaderStyle)),
              Expanded(flex: 2, child: Text('WILAYAH PESISIR', style: _colHeaderStyle)),
              SizedBox(width: 120, child: Align(alignment: Alignment.centerRight, child: Text('AKSI', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        ...reports.map((report) => _buildDesktopRow(report)),
      ],
    );
  }

  Widget _buildDesktopRow(ReportModel report) {
    return InkWell(
      onTap: () => widget.onNavigateToReview(report.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto
            SizedBox(
              width: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SafeAppImage(imageUrl: report.beforePhotoUrl, width: 38, height: 28, fit: BoxFit.cover),
              ),
            ),

            // Tanggal
            SizedBox(
              width: 100,
              child: Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(report.createdAt),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ),

            // Status
            SizedBox(
              width: 155,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: report.status, isCompact: true),
                ),
              ),
            ),

            // Kategori
            SizedBox(
              width: 165,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  report.categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Deskripsi
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  report.description.isEmpty ? 'Tidak ada deskripsi rinci' : report.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Wilayah
            Expanded(
              flex: 2,
              child: Text(
                report.locationName ?? 'Pesisir Lapangan',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Button
            // Button & Delete Action
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => widget.onNavigateToReview(report.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Kelola', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Hapus Laporan',
                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteReport(report),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(List<ReportModel> reports, {bool isTablet = false}) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Tidak ada laporan yang ditemukan.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ),
      );
    }

    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: reports.map((r) => SizedBox(width: colWidth, child: _buildMobileCard(r))).toList(),
            );
          },
        ),
      );
    }

    return Column(
      children: reports.map((report) => _buildMobileCard(report)).toList(),
    );
  }

  Widget _buildMobileCard(ReportModel report) {
    return InkWell(
      onTap: () => widget.onNavigateToReview(report.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SafeAppImage(
                imageUrl: report.beforePhotoUrl,
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
                      Expanded(
                        child: Text(
                          report.categoryName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: report.status, isCompact: true),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Hapus Laporan',
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteReport(report),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${report.locationName ?? 'Pesisir Lapangan'} • ${DateFormat('dd MMM yyyy', 'id_ID').format(report.createdAt)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description.isEmpty ? 'Tidak ada deskripsi rinci' : report.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ReportModel> get _filteredReports {
    return _reportService.reports.where((r) {
      // Filter status
      if (_selectedStatus != 'all') {
        if (_selectedStatus == 'pending_review' && r.status != ReportStatus.pendingReview) return false;
        if (_selectedStatus == 'verified' && r.status != ReportStatus.verified) return false;
        if ((_selectedStatus == 'in_progress' || _selectedStatus == 'in_cleanup') && r.status != ReportStatus.inProgress) return false;
        if (_selectedStatus == 'pending_cleanup' && r.status != ReportStatus.pendingCleanupReview) return false;
        if (_selectedStatus == 'cleaned' && r.status != ReportStatus.cleaned) return false;
        if (_selectedStatus == 'rejected' && r.status != ReportStatus.rejected) return false;
        if (_selectedStatus == 'duplicate' && r.status != ReportStatus.duplicate) return false;
      }

      // Filter kategori
      if (_selectedCategory != 'all') {
        final catName = r.categoryName.toLowerCase();
        if (!catName.contains(_selectedCategory.toLowerCase())) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = r.id.toLowerCase().contains(q);
        final matchLoc = (r.locationName ?? '').toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        final matchCat = r.categoryName.toLowerCase().contains(q);
        if (!matchId && !matchLoc && !matchDesc && !matchCat) return false;
      }

      return true;
    }).toList();
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
  );
}
