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

              // 2. Role Switcher for Demo & Presentation (Section 15.10 & 20)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.navy),
                        SizedBox(width: 6),
                        Text(
                          'Peralihan Cepat Peran Demo (Testing)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ganti mode aktor secara instan untuk mendemokan alur Pengunjung, Pelapor, atau Relawan:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRoleChip(context, 'Pengunjung', UserRole.guest, authService),
                        const SizedBox(width: 8),
                        _buildRoleChip(context, 'Pelapor', UserRole.reporter, authService),
                        const SizedBox(width: 8),
                        _buildRoleChip(context, 'Relawan', UserRole.cleaner, authService),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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

  Widget _buildRoleChip(BuildContext context, String label, UserRole role, AuthService auth) {
    final isSelected = auth.currentRole == role;
    return Expanded(
      child: InkWell(
        onTap: () {
          auth.switchRoleForDemo(role);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.navy : AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.navy : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.white : AppTheme.navy,
            ),
          ),
        ),
      ),
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
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
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
