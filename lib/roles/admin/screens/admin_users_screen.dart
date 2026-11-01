import 'package:flutter/material.dart';
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
                              'Menampilkan ${users.length} dari 342 akun relawan pesisir',
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
              Expanded(flex: 3, child: Text('RELAWAN / PENGGUNA', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('EMAIL (TERSAMARKAN)', style: _colHeaderStyle)),
              Expanded(flex: 3, child: Text('WILAYAH PESISIR UTAMA', style: _colHeaderStyle)),
              SizedBox(width: 90, child: Text('BERGABUNG', style: _colHeaderStyle)),
              Expanded(flex: 2, child: Text('LAPORAN (VALID/TOLAK)', style: _colHeaderStyle)),
              SizedBox(width: 90, child: Align(alignment: Alignment.centerRight, child: Text('VALIDITAS', style: _colHeaderStyle))),
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
                  flex: 3,
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
                  flex: 3,
                  child: Text(
                    user.maskedEmail,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Wilayah
                Expanded(
                  flex: 3,
                  child: Text(
                    user.primaryRegion,
                    style: TextStyle(fontSize: 11, color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF1E293B)),
                  ),
                ),

                // Bergabung
                const SizedBox(
                  width: 90,
                  child: Text('12 Sep 2024', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ),

                // Laporan
                Expanded(
                  flex: 2,
                  child: Text(
                    '${user.validReportsCount}V / ${user.rejectedReportsCount}X',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),

                // Validitas
                SizedBox(
                  width: 90,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(user.validityRate * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSpam ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
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
                  Text(u.id, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 2),
              Text(u.maskedEmail, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
              Text(u.primaryRegion, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
              const SizedBox(height: 4),
              Text('Total: ${u.totalReports} Laporan • Validitas: ${(u.validityRate * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
