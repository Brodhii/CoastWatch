import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../models/category_model.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../widgets/duplicate_report_dialog.dart';
import '../widgets/reject_report_dialog.dart';

class AdminReviewDetailScreen extends StatefulWidget {
  final String reportId;
  final VoidCallback onBackToQueue;

  const AdminReviewDetailScreen({
    super.key,
    required this.reportId,
    required this.onBackToQueue,
  });

  @override
  State<AdminReviewDetailScreen> createState() => _AdminReviewDetailScreenState();
}

class _AdminReviewDetailScreenState extends State<AdminReviewDetailScreen> {
  final ReportService _reportService = ReportService();
  late TextEditingController _notesController;
  final MapController _mapController = MapController();
  late String _currentReportId;

  @override
  void initState() {
    super.initState();
    _currentReportId = widget.reportId;
    _notesController = TextEditingController(
      text: 'Bukti visual jelas berupa sampah anorganik di zona intertidal muara. Koordinat sesuai garis pantai Teluk Naga.',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  CategoryModel _getCategoryForReport(ReportModel report) {
    return CategoryModel.defaultCategories.firstWhere(
      (c) =>
          c.id.toLowerCase() == report.categoryId.toLowerCase() ||
          c.name.toLowerCase() == report.categoryName.toLowerCase(),
      orElse: () => CategoryModel(
        id: report.categoryId,
        name: report.categoryName,
        description: 'Laporan temuan pesisir kategori ${report.categoryName}.',
        icon: Icons.delete_outline,
        code: 'CW-CAT-01',
      ),
    );
  }

  void _verifyReport(ReportModel report) async {
    try {
      await _reportService.adminVerifyReport(_currentReportId, notes: _notesController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan #${report.id} disetujui untuk publikasi ke peta GIS.'),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _showRejectDialog(ReportModel report) {
    RejectReportDialog.show(
      context,
      reportId: report.id,
      onConfirmReject: (reason) async {
        await _reportService.adminRejectReport(report.id, reason: reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan #${report.id} ditolak dengan alasan tersimpan.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      },
    );
  }

  void _showDuplicateDialog(ReportModel report) {
    DuplicateReportDialog.show(
      context,
      reportId: report.id,
      onConfirmDuplicate: (originalId, notes) async {
        await _reportService.adminMarkDuplicate(report.id, duplicateOfReportId: originalId, notes: notes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan #${report.id} ditandai duplikat dari #$originalId.'),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final report = _reportService.getReportById(_currentReportId) ?? _reportService.reports.first;
        final category = _getCategoryForReport(report);

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return ListView(
              padding: EdgeInsets.all(isSmall ? 14 : 20),
              children: [
                // 1. Navigation & Header
                _buildBreadcrumbsAndTitle(report, isSmall),

                const SizedBox(height: 16),

                // 2. Main Content
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Evidence + GIS
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPhotoEvidenceCard(report),
                            const SizedBox(height: 16),
                            _buildGisMapCard(report),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      // RIGHT: Citizen report, Category, Technical audit, Notes, Actions
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCitizenReportCard(report, category),
                            const SizedBox(height: 16),
                            _buildTechnicalAuditCard(report),
                            const SizedBox(height: 16),
                            _buildVerifierNotesCard(),
                            const SizedBox(height: 16),
                            _buildActionButtonsCard(report),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Mobile & Tablet
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCitizenReportCard(report, category),
                      const SizedBox(height: 14),
                      _buildPhotoEvidenceCard(report),
                      const SizedBox(height: 14),
                      _buildGisMapCard(report),
                      const SizedBox(height: 14),
                      _buildTechnicalAuditCard(report),
                      const SizedBox(height: 14),
                      _buildVerifierNotesCard(),
                      const SizedBox(height: 14),
                      _buildActionButtonsCard(report),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // BREADCRUMBS & TICKET TITLE HEADER (Pure typography, no icons)
  Widget _buildBreadcrumbsAndTitle(ReportModel report, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onBackToQueue,
              child: const Text(
                '← Kembali ke Antrean',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
            Text(
              'Tiket #${report.id}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${report.id}',
                  style: TextStyle(
                    fontSize: isSmall ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                  ),
                  child: Text(
                    report.status.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: widget.onBackToQueue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Antrean', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),

        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text(
              'Pelapor: Terverifikasi',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
            const Text(
              'Waktu Masuk: 15 Okt 2024, 09:25 WIB',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  // 1. CARD: PHOTO EVIDENCE (No icons)
  Widget _buildPhotoEvidenceCard(ReportModel report) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bukti Foto Lapangan Resolusi Penuh',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'SHA-256 Valid',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  report.beforePhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1E293B),
                    alignment: Alignment.center,
                    child: const Text('Foto Bukti Lapangan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: Colors.black.withValues(alpha: 0.8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXIF: 4032 × 3024 • ISO 50 • 26mm f/1.8',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'monospace'),
                      ),
                      Text(
                        'Geotag Sensor Presisi',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showImageZoomDialog(context, report.beforePhotoUrl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Perbesar Foto (Zoom)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. CARD: GIS MAP (No icons, crosshair pinpoint)
  Widget _buildGisMapCard(ReportModel report) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Penanda Titik Lokasi Pesisir GIS',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Text(
                  '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(report.latitude, report.longitude),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.osmUserAgent,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(report.latitude, report.longitude),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Lokasi: ${report.locationName ?? "Zona Intertidal Pesisir"} (Koordinat EXIF terkunci dari berkas asli)',
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. CARD: INFORMASI LAPORAN WARGA
  // CATEGORY IS 100% CLEAR, HIGH-CONTRAST, READABLE, NO ICONS
  Widget _buildCitizenReportCard(ReportModel report, CategoryModel category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Clean Category Label (Fully visible, no background color, no truncation)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Laporan Warga',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Kategori: ${category.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'DESKRIPSI PELAPOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '“${report.description}”',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), height: 1.45),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Waktu Foto', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('09:14 WIB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Waktu Server', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('09:25 WIB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. CARD: AUDIT TEKNIS SISTEM (Pure text, zero icons)
  Widget _buildTechnicalAuditCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audit Teknis Sistem',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                'V4.2',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildAuditRow('Status GPS EXIF', 'Geodesik WGS84 valid terverifikasi', 'VALID'),
          const SizedBox(height: 6),
          _buildAuditRow('Konsistensi Waktu', 'Waktu perangkat sinkron dengan server', 'VALID'),
          const SizedBox(height: 6),
          _buildAuditRow('Metadata File', 'Header berkas utuh tanpa modifikasi', 'NORMAL'),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String title, String subtitle, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 5. CARD: CATATAN INTERNAL
  Widget _buildVerifierNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Internal Verifikator',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
        ],
      ),
    );
  }

  // 6. CARD: AKSI KEPUTUSAN (No icons, clean buttons)
  Widget _buildActionButtonsCard(ReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AKSI KEPUTUSAN ADMINISTRATIF',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        // Primary: Verifikasi Laporan
        ElevatedButton(
          onPressed: () => _verifyReport(report),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          child: const Text(
            'Verifikasi Laporan (Setujui ke Peta Publik)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),

        const SizedBox(height: 8),

        // Secondary: Tolak & Duplikat
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRejectDialog(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Tolak Laporan...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showDuplicateDialog(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Tandai Duplikat...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showImageZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('[Tutup]', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
