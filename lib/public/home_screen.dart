import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../shared/empty_state_view.dart';
import '../shared/guest_prompt_dialog.dart';
import '../shared/report_card.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final reportService = ReportService();
    final isGuest = authService.isGuest;

    return ListenableBuilder(
      listenable: Listenable.merge([authService, reportService]),
      builder: (context, _) {
        final verifiedReports = reportService.getPublicReports();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.waves, color: AppTheme.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CoastWatch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      'Pelaporan Pesisir & Geotagging',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (isGuest)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('Masuk'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        authService.currentRole.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.teal,
            onRefresh: () async {
              // Refresh state
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Header & Context Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dokumentasikan & Lindungi Pesisir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Laporkan temuan sampah laut dan pencemaran pesisir dengan bukti foto ber-geotag valid dari kamera perangkat.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.skyBlue,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (authService.isGuest) {
                                  GuestPromptDialog.show(
                                    context,
                                    title: 'Kirim Laporan Pesisir',
                                    description: 'Silakan masuk atau daftar akun pelapor terlebih dahulu untuk mengirimkan bukti foto ber-geotag.',
                                  );
                                } else {
                                  Navigator.pushNamed(context, AppRoutes.createReportCamera);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.teal,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              label: const Text(
                                'Buat Laporan',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (onNavigateTab != null) {
                                  onNavigateTab!(1); // Navigate to Map tab
                                } else {
                                  Navigator.pushNamed(context, AppRoutes.initial);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.white,
                                side: const BorderSide(color: AppTheme.skyBlue),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text(
                                'Buka Peta',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Explanatory Context Note (Desain.md Section 15.4 point 5)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlue.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppTheme.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Laporan pada peta publik telah diverifikasi Admin berdasarkan bukti digital EXIF GPS. Status terverifikasi tidak otomatis menyatakan lokasi telah dikunjungi langsung di lapangan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.navy,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Section Title: Laporan Terverifikasi Terbaru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Laporan Terverifikasi Publik',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(1); // Go to map
                        }
                      },
                      child: const Text('Lihat di Peta'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 4. Report List
                if (verifiedReports.isEmpty)
                  const EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'Belum Ada Laporan Terverifikasi',
                    message: 'Laporan warga pesisir yang telah lolos verifikasi digital akan ditampilkan di sini.',
                  )
                else
                  ...verifiedReports.map((report) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReportCard(
                          report: report,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.publicReportDetail,
                              arguments: report.id,
                            );
                          },
                        ),
                      )),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
