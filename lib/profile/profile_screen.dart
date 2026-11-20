import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../shared/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;
        final isGuest = authService.isGuest;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil & Akun'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. User Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.navy,
                      child: Text(
                        isGuest ? 'G' : (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGuest ? 'Mode Pengunjung (Belum Masuk)' : user.email,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.skyBlue.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              user.role.label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Action Card based on Authentication State
              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akses Akun CoastWatch',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masuk dengan username/email dan kata sandi Anda untuk mengakses hak akses Pelapor, Relawan Pembersih, atau Admin.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.login, size: 16),
                              label: const Text('Masuk ke Akun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppTheme.navy),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Daftar Akun', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.navy)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (user.isAdmin) ...[
                // Admin Console Entry
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, color: AppTheme.navy, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Konsol Admin Operasional',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kelola verifikasi antrean laporan masuk, validasi aksi bersih relawan, dan pantau log audit sistem.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.adminShell),
                          child: const Text('Buka Konsol Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Information & Privacy Section (Section 15.9)
              const Text(
                'Informasi & Keamanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
              const SizedBox(height: 8),

              _buildTile(
                icon: Icons.camera_alt_outlined,
                title: 'Izin Kamera & Sensor Lokasi',
                subtitle: 'Kamera dan GPS digunakan saat mengambil foto bukti untuk menyematkan tag koordinat valid.',
                onTap: () {
                  _showInfoDialog(
                    context,
                    title: 'Izin Kamera & Lokasi',
                    message:
                        'CoastWatch memerlukan izin kamera untuk mendokumentasikan bukti temuan pesisir dan izin lokasi untuk menyematkan tag EXIF GPS. Koordinat diperoleh saat pemotretan berlangsung.',
                  );
                },
              ),
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Kebijakan Privasi Geotagging',
                subtitle: 'Foto asli disimpan privat. Identitas dan kontak pelapor tidak pernah ditampilkan di peta publik.',
                onTap: () {
                  _showInfoDialog(
                    context,
                    title: 'Kebijakan Privasi',
                    message:
                        'Foto asli disimpan dalam bucket privat. Hanya laporan terverifikasi dengan foto turunan yang ditampilkan pada peta publik. Data pribadi pelapor dilindungi dan tidak dibagikan kepada publik.',
                  );
                },
              ),
              _buildTile(
                icon: Icons.help_outline,
                title: 'Tentang CoastWatch Citizen Science',
                subtitle: 'Aplikasi pelaporan pesisir berbasis partisipasi masyarakat dengan verifikasi digital.',
                onTap: () {
                  _showInfoDialog(
                    context,
                    title: 'Tentang CoastWatch',
                    message:
                        'CoastWatch versi 1.0.0 dikembangkan untuk mendukung pemantauan lingkungan pesisir melalui citizen science berbasis geotagging foto dan tindak lanjut aksi bersih relawan.',
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4. Auth Actions
              if (isGuest) ...[
                AppButton(
                  label: 'Masuk ke Akun',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Daftar Akun Baru',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                  variant: AppButtonVariant.outlined,
                ),
              ] else ...[
                AppButton(
                  label: 'Keluar dari Akun',
                  onPressed: () async {
                    await authService.signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Anda telah kembali ke mode Pengunjung.')),
                    );
                  },
                  variant: AppButtonVariant.outlined,
                  icon: Icons.logout,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(icon, color: AppTheme.teal, size: 22),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
