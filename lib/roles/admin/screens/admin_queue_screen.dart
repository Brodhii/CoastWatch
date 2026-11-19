import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../../../shared/safe_app_image.dart';
import '../../../shared/status_badge.dart';

class AdminQueueScreen extends StatefulWidget {
  final ValueChanged<String> onNavigateToReview;

  const AdminQueueScreen({
    super.key,
    required this.onNavigateToReview,
  });

  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  final ReportService _reportService = ReportService();
  String _searchQuery = '';
  String _selectedStage = 'all';
  String _selectedCategory = 'all';
  final Set<String> _selectedReportIds = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final reports = _filteredReports;

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
                  // 1. Header (Simple, clean, without busy tabs)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verifikasi Laporan',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${reports.length} laporan masuk menunggu peninjauan dan validasi sebelum dipublikasikan ke peta umum.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // 2. Simple Filter Bar (EXIF filter removed, no color clutter)
                _buildFilterBar(isDesktop),

                const SizedBox(height: 14),

                // 3. Queue Table View (Desktop) vs Mobile Card List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (isDesktop)
                        _buildDesktopQueueTable(reports)
                      else
                        _buildMobileQueueList(reports, isTablet: w >= 640),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      // Pagination Footer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menampilkan ${reports.length} laporan antrean',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
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

                // 4. Privacy Note (Simple, clean text)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Identitas pelapor dirahasiakan dari publik dan hanya diakses oleh Admin untuk keperluan validasi lapangan CoastWatch GIS.',
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

  // FILTER CONTROLS BAR (No EXIF filter, simple & clean)
  Widget _buildFilterBar(bool isDesktop) {
    final searchBox = SizedBox(
      height: 36,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          hintText: 'Cari kata kunci atau wilayah...',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        ),
      ),
    );

    final stageDropdown = _buildDropdown(
      value: _selectedStage,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Antrean')),
        DropdownMenuItem(value: 'pending_review', child: Text('Tahap 1: Laporan Masuk')),
        DropdownMenuItem(value: 'pending_cleanup', child: Text('Tahap 2: Validasi Bersih')),
      ],
      onChanged: (v) => setState(() => _selectedStage = v ?? 'all'),
    );

    final categoryDropdown = _buildDropdown(
      value: _selectedCategory,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
        DropdownMenuItem(value: 'plastic', child: Text('Sampah Plastik')),
        DropdownMenuItem(value: 'liquid', child: Text('Limbah Cair / Minyak')),
        DropdownMenuItem(value: 'fishing', child: Text('Alat Tangkap & Jaring')),
        DropdownMenuItem(value: 'household', child: Text('Sampah Rumah Tangga')),
        DropdownMenuItem(value: 'ecosystem', child: Text('Kerusakan Ekosistem')),
        DropdownMenuItem(value: 'organic', child: Text('Sampah Organik')),
      ],
      onChanged: (v) => setState(() => _selectedCategory = v ?? 'all'),
    );

    final resetButton = TextButton(
      onPressed: () {
        setState(() {
          _searchQuery = '';
          _selectedStage = 'all';
          _selectedCategory = 'all';
        });
      },
      child: const Text('Reset Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
    );

    final bulkValidateButton = ElevatedButton(
      onPressed: _selectedReportIds.isEmpty
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_selectedReportIds.length} laporan terpilih disetujui.')),
              );
              setState(() => _selectedReportIds.clear());
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      child: Text('Validasi Terpilih (${_selectedReportIds.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );

    if (isDesktop) {
      return Row(
        children: [
          SizedBox(width: 220, child: searchBox),
          const SizedBox(width: 8),
          stageDropdown,
          const SizedBox(width: 8),
          categoryDropdown,
          const SizedBox(width: 8),
          resetButton,
          const Spacer(),
          bulkValidateButton,
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
                stageDropdown,
                const SizedBox(width: 8),
                categoryDropdown,
                const SizedBox(width: 8),
                resetButton,
                const SizedBox(width: 8),
                bulkValidateButton,
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

  // DESKTOP QUEUE TABLE
  // Ample width for Category so names are NEVER truncated with "..."
  Widget _buildDesktopQueueTable(List<ReportModel> reports) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: _selectedReportIds.length == reports.length && reports.isNotEmpty,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedReportIds.addAll(reports.map((r) => r.id));
                    } else {
                      _selectedReportIds.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 44, child: Text('FOTO', style: _colHeaderStyle)),
              const SizedBox(width: 90, child: Text('ID & WAKTU', style: _colHeaderStyle)),
              // WIDE COLUMN FOR CATEGORY SO IT DOES NOT TRUNCATE WITH "..."
              const SizedBox(width: 220, child: Text('KATEGORI TEMUAN', style: _colHeaderStyle)),
              const Expanded(flex: 3, child: Text('RINGKASAN DESKRIPSI', style: _colHeaderStyle)),
              const Expanded(flex: 2, child: Text('WILAYAH PESISIR', style: _colHeaderStyle)),
              const SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('AKSI', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),

        ...reports.map((report) => _buildDesktopQueueRow(report)),
      ],
    );
  }

  Widget _buildDesktopQueueRow(ReportModel report) {
    final isSelected = _selectedReportIds.contains(report.id);

    return InkWell(
      onTap: () => widget.onNavigateToReview(report.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedReportIds.add(report.id);
                  } else {
                    _selectedReportIds.remove(report.id);
                  }
                });
              },
            ),

            // Photo
            SizedBox(
              width: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SafeAppImage(imageUrl: report.beforePhotoUrl, width: 38, height: 28, fit: BoxFit.cover),
              ),
            ),

            // Wilayah & Waktu
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.locationName ?? 'Pesisir Batam',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(report.createdAt),
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),

            // KATEGORI TEMUAN: Fully readable, no ellipsis (...), no background color
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  report.categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
              ),
            ),

            // Deskripsi
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  report.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                  maxLines: 2,
                ),
              ),
            ),

            // Wilayah Pesisir
            Expanded(
              flex: 2,
              child: Text(
                report.locationName ?? 'Pesisir Lapangan',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                maxLines: 2,
              ),
            ),

            // Button
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => widget.onNavigateToReview(report.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: report.isPendingCleanupReview ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                    backgroundColor: report.isPendingCleanupReview ? const Color(0xFFF5F3FF) : Colors.transparent,
                    side: BorderSide(color: report.isPendingCleanupReview ? const Color(0xFFDDD6FE) : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    report.isPendingCleanupReview ? 'Validasi Bersih' : 'Buka Verifikasi',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MOBILE & TABLET CARDS
  Widget _buildMobileQueueList(List<ReportModel> reports, {bool isTablet = false}) {
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
    final isSelected = _selectedReportIds.contains(report.id);

    return InkWell(
      onTap: () => widget.onNavigateToReview(report.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
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
                      Text(report.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      StatusBadge(status: report.status, isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // KATEGORI FULLY VISIBLE, NO TRUNCATION
                  Text(
                    report.categoryName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.locationName ?? 'Pesisir Lapangan',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => widget.onNavigateToReview(report.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: report.isPendingCleanupReview ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                        backgroundColor: report.isPendingCleanupReview ? const Color(0xFFF5F3FF) : Colors.transparent,
                        side: BorderSide(color: report.isPendingCleanupReview ? const Color(0xFFDDD6FE) : const Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        report.isPendingCleanupReview ? 'Validasi Pembersihan' : 'Buka Verifikasi',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
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
      // Filter status antrean: Laporan Masuk (Tahap 1) atau Validasi Pembersihan Relawan (Tahap 2)
      final isQueueItem = r.status == ReportStatus.pendingReview || r.status == ReportStatus.pendingCleanupReview;
      if (!isQueueItem) return false;

      if (_selectedStage == 'pending_review' && r.status != ReportStatus.pendingReview) {
        return false;
      }
      if (_selectedStage == 'pending_cleanup' && r.status != ReportStatus.pendingCleanupReview) {
        return false;
      }

      if (_selectedCategory != 'all' && r.categoryId.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

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
    letterSpacing: 0.5,
  );
}
