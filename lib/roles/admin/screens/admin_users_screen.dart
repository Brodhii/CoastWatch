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
                // 1. Tag & Header
                Column(
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
                      'Kelola akses akun dan penanganan penyalahgunaan sistem pelaporan tanpa mengungkap kredensial sensitif.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
              SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('STATUS AKUN', style: _colHeaderStyle))),
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
                // User initials & Name
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSpam ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSpam ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          initials,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(user.id, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                          ],
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
                  width: 100,
                  child: Align(
                    alignment: Alignment.centerRight,
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
