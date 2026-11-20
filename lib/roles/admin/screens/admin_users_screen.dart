import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/admin_user_model.dart';
import '../../../services/report_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    // Sinkronkan data pengguna secara langsung dari database Supabase
    _reportService.fetchAdminUsers();
  }

  // ================= DIALOG TAMBAH PENGGUNA =================
  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'reporter'; // 'reporter', 'cleaner', 'admin'
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, size: 20, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Pengguna Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan informasi pengguna baru untuk didaftarkan ke sistem dan database.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),

                        // Nama Pengguna
                        const Text('Nama Lengkap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration(hint: 'Contoh: Ahmad Yani'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email / Username
                        const Text('Email / Username Akun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: emailController,
                          decoration: _inputDecoration(hint: 'Contoh: ahmad.yani@coastwatch.id'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email/Username tidak boleh kosong';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Peran / Role
                        const Text('Peran Pengguna', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          isDense: true,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'reporter', child: Text('Pelapor Warga', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'cleaner', child: Text('Relawan Pesisir', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'admin', child: Text('Admin Operasional', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Kata Sandi
                        const Text('Kata Sandi Akun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: _inputDecoration(
                            hint: 'Minimal 6 karakter',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setDialogState(() => obscurePassword = !obscurePassword);
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Catatan: Kata sandi tersimpan aman dan tidak akan ditampilkan di tabel.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final nav = Navigator.of(ctx);
                    final scaffold = ScaffoldMessenger.of(context);

                    final success = await _reportService.adminAddUser(
                      name: nameController.text,
                      email: emailController.text,
                      role: selectedRole,
                      password: passwordController.text,
                    );

                    nav.pop();
                    if (success) {
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Pengguna "${nameController.text.trim()}" berhasil ditambahkan.'),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Simpan Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DIALOG EDIT PENGGUNA =================
  void _showEditUserDialog(AdminUserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final passwordController = TextEditingController();
    String selectedRole = user.rawRole; // 'reporter', 'cleaner', 'admin'
    bool isActive = !user.isSuspended;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: Row(
                children: [
                  const Icon(Icons.edit_note, size: 22, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Pengguna: ${user.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perbarui informasi pengguna, hak peran, status akun, atau reset kata sandi.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),

                        // Nama Pengguna
                        const Text('Nama Lengkap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Peran / Role
                        const Text('Peran Pengguna', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          isDense: true,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'reporter', child: Text('Pelapor Warga', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'cleaner', child: Text('Relawan Pesisir', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'admin', child: Text('Admin Operasional', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Status Akun
                        const Text('Status Akses Akun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<bool>(
                          initialValue: isActive,
                          isDense: true,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Aktif (Bisa Mengakses)', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)))),
                            DropdownMenuItem(value: false, child: Text('Ditangguhkan / Nonaktif', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => isActive = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Kata Sandi Baru (Opsional)
                        const Text('Kata Sandi Baru (Opsional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: _inputDecoration(
                            hint: 'Kosongkan jika tidak ingin mengubah sandi',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setDialogState(() => obscurePassword = !obscurePassword);
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && val.length < 6) {
                              return 'Kata sandi baru minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Catatan: Kata sandi tersimpan aman dan tidak akan ditampilkan di tabel konsol.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final nav = Navigator.of(ctx);
                    final scaffold = ScaffoldMessenger.of(context);

                    final success = await _reportService.adminUpdateUser(
                      userId: user.id,
                      name: nameController.text,
                      role: selectedRole,
                      isActive: isActive,
                      newPassword: passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : null,
                    );

                    nav.pop();
                    if (success) {
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Data pengguna "${nameController.text.trim()}" berhasil diperbarui.'),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DIALOG KONFIRMASI HAPUS =================
  void _confirmDeleteUser(AdminUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 8),
              Text(
                'Hapus Pengguna?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun "${user.name}"?\nData akun akan dihapus dari sistem registry dan database Supabase.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final scaffold = ScaffoldMessenger.of(context);

                final success = await _reportService.adminDeleteUser(user.id);

                nav.pop();
                if (success) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Pengguna "${user.name}" berhasil dihapus dari sistem.'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Hapus Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final users = _reportService.adminUsers;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 980;
            final isSmall = w < 640;

            return ListView(
              padding: EdgeInsets.all(isSmall ? 14 : 20),
              children: [
                // 1. Tag & Header + Tombol Tambah Pengguna
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REGISTRY & VERIFIKASI KREDENSIAL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pengguna & Relawan Lapangan',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kelola akses akun, hak peran (admin/relawan/pelapor), status akun, serta reset kredensial pengguna.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      label: const Text('Tambah Pengguna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. User Table (Desktop) vs Mobile User Cards
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Subheader
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Daftar Pengguna & Relawan',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(3)),
                                  child: Text('${users.length} Akun', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                            const Text('Registry Master Pengguna', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      if (isDesktop)
                        _buildDesktopUserTable(users)
                      else
                        _buildMobileUserList(users),

                      const Divider(color: Color(0xFFE2E8F0), height: 1),

                      // Pagination
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              users.isEmpty
                                  ? 'Tidak ada akun terdaftar'
                                  : 'Menampilkan ${users.length} akun terdaftar',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopUserTable(List<AdminUserModel> users) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: const Row(
            children: [
              Expanded(flex: 4, child: Text('RELAWAN / PENGGUNA', style: _colHeaderStyle)),
              Expanded(flex: 4, child: Text('EMAIL (TERSAMARKAN)', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('PERAN & WILAYAH', style: _colHeaderStyle)),
              Expanded(flex: 2, child: Text('BERGABUNG', style: _colHeaderStyle)),
              SizedBox(width: 90, child: Align(alignment: Alignment.center, child: Text('STATUS AKUN', style: _colHeaderStyle))),
              SizedBox(width: 140, child: Align(alignment: Alignment.centerRight, child: Text('PENGELOLAAN', style: _colHeaderStyle))),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        ...users.map((user) {
          final isSpam = user.isSuspended;
          final initials = user.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              children: [
                // User initials & Name ONLY (ID mentah di bawah username DIHAPUS TOTAL)
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSpam ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSpam ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          initials,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Masked email
                Expanded(
                  flex: 4,
                  child: Text(
                    user.maskedEmail,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Peran & Wilayah
                Expanded(
                  flex: 3,
                  child: Text(
                    user.primaryRegion,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF1E293B)),
                  ),
                ),

                // Bergabung
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(user.joinedDate),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),

                // Status Akun
                SizedBox(
                  width: 90,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSpam ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isSpam ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        isSpam ? 'Ditangguhkan' : 'Aktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pengelolaan (Edit & Hapus)
                SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _showEditUserDialog(user),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () => _confirmDeleteUser(user),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
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
  }

  Widget _buildMobileUserList(List<AdminUserModel> users) {
    return Column(
      children: users.map((u) {
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
                  Text(u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: u.isSuspended ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      u.isSuspended ? 'Ditangguhkan' : 'Aktif',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: u.isSuspended ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(u.maskedEmail, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text('${u.primaryRegion} • Bergabung ${DateFormat("dd MMM yyyy", "id_ID").format(u.joinedDate)}', style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showEditUserDialog(u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _confirmDeleteUser(u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
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
