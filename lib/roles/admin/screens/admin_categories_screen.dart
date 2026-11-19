import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../services/report_service.dart';
import '../widgets/admin_action_button.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final categories = _reportService.categories;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return ListView(
              padding: EdgeInsets.all(isSmall ? 14 : 20),
              children: [
                // 1. Header & Tambah Kategori
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manajemen Kategori Lingkungan',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kelola jenis klasifikasi temuan pesisir: tambah, edit nama/kode, aktifkan/nonaktifkan, atau hapus kategori.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showAddCategoryDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Tambah Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Category Table / Cards (Real CRUD Table)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Daftar Kategori',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(3)),
                                  child: Text('${categories.length} Kategori', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                            const Text('Pengelolaan Master Data', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      if (isDesktop)
                        _buildDesktopCategoryTable(categories)
                      else
                        _buildMobileCategoryCards(categories),
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

  static const double _tableMinWidth = 900;

  Widget _buildDesktopCategoryTable(List<CategoryModel> categories) {
    final table = Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: const Row(
            children: [
              SizedBox(width: 48, child: Text('NO', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('NAMA KATEGORI & KODE', style: _colHeaderStyle)),
              Expanded(flex: 5, child: Text('DESKRIPSI & CAKUPAN TEMUAN', style: _colHeaderStyle)),
              SizedBox(width: 110, child: Text('TOTAL LAPORAN', style: _colHeaderStyle)),
              SizedBox(width: 110, child: Text('STATUS', style: _colHeaderStyle)),
              SizedBox(width: 250, child: Align(alignment: Alignment.centerRight, child: Text('PENGELOLAAN', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final cat = entry.value;

          return Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(index.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF64748B))),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(cat.code, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      cat.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text('${cat.reportCount} Lap.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ),
                SizedBox(
                  width: 110,
                  child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(cat.isActive)),
                ),
                SizedBox(
                  width: 250,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AdminActionButton(
                        label: 'Edit',
                        minWidth: 62,
                        onPressed: () => _showEditCategoryDialog(cat),
                      ),
                      const SizedBox(width: 8),
                      AdminActionButton(
                        label: cat.isActive ? 'Nonaktif' : 'Aktifkan',
                        minWidth: 84,
                        tone: cat.isActive ? AdminButtonTone.warning : AdminButtonTone.success,
                        onPressed: () => _toggleCategoryStatus(cat),
                      ),
                      const SizedBox(width: 8),
                      AdminActionButton(
                        label: 'Hapus',
                        minWidth: 66,
                        tone: AdminButtonTone.danger,
                        onPressed: () => _confirmDeleteCategory(cat),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );

    // Jika area sempit, tabel bisa digeser horizontal agar tidak overflow.
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= _tableMinWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _tableMinWidth, child: table),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final fg = isActive ? const Color(0xFF15803D) : const Color(0xFF64748B);
    final bg = isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildMobileCategoryCards(List<CategoryModel> categories) {
    return Column(
      children: categories.map((cat) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  ),
                  const SizedBox(width: 8),
                  Text(cat.code, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 4),
              Text(cat.description, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusBadge(cat.isActive),
                  const SizedBox(width: 8),
                  Text('${cat.reportCount} Laporan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AdminActionButton(
                      label: 'Edit',
                      expand: true,
                      onPressed: () => _showEditCategoryDialog(cat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminActionButton(
                      label: cat.isActive ? 'Nonaktif' : 'Aktifkan',
                      expand: true,
                      tone: cat.isActive ? AdminButtonTone.warning : AdminButtonTone.success,
                      onPressed: () => _toggleCategoryStatus(cat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminActionButton(
                      label: 'Hapus',
                      expand: true,
                      tone: AdminButtonTone.danger,
                      onPressed: () => _confirmDeleteCategory(cat),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // DIALOG TAMBAH KATEGORI BARU
  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'CW-CAT-0${_reportService.categories.length + 1}');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Tambah Kategori Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Kategori:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: Limbah Minyak / Aspal',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Kode Kategori:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: CW-CAT-08',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Deskripsi & Cakupan Temuan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Penjelasan jenis temuan untuk panduan pelapor...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              _reportService.addCategory(
                name: name,
                code: codeCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$name" berhasil ditambahkan.')),
              );
            },
            child: const Text('Simpan Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // DIALOG EDIT KATEGORI
  void _showEditCategoryDialog(CategoryModel cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    final codeCtrl = TextEditingController(text: cat.code);
    final descCtrl = TextEditingController(text: cat.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Edit Kategori: ${cat.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Kategori:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Kode Kategori:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Deskripsi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              _reportService.updateCategory(cat.copyWith(
                name: newName,
                code: codeCtrl.text.trim(),
                description: descCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$newName" berhasil diperbarui.')),
              );
            },
            child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleCategoryStatus(CategoryModel cat) {
    _reportService.toggleCategoryActive(cat.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status kategori "${cat.name}" diubah menjadi ${!cat.isActive ? "Aktif" : "Nonaktif"}.')),
    );
  }

  void _confirmDeleteCategory(CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Hapus Kategori "${cat.name}"?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${cat.name}" (${cat.code}) dari master data?', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            onPressed: () {
              _reportService.deleteCategory(cat.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "${cat.name}" telah dihapus.')),
              );
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.6,
  );
}
