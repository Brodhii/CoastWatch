import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/empty_state_view.dart';
import '../widgets/task_card.dart';

class CleanerDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const CleanerDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final authService = AuthService();

    return ListenableBuilder(
      listenable: Listenable.merge([reportService, authService]),
      builder: (context, _) {
        final availableTasks = reportService.getAvailableTasks();
        final myTasks = reportService.getMyTasks();
        final inProgressTasks = myTasks.where((t) => t.isInProgress).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dasbor Relawan Pembersih',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                Text(
                  authService.currentUser.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            color: AppTheme.teal,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Tasks Banner (if any task is currently in progress)
                if (inProgressTasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.statusInProgressBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.statusInProgress.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.handyman_outlined, color: AppTheme.statusInProgress, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${inProgressTasks.length} Tugas Sedang Ditangani',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusInProgress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Selesaikan pembersihan di lapangan lalu unggah foto bukti sesudah pembersihan ber-geotag valid.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.cleanerTaskDetail,
                                arguments: inProgressTasks.first.id,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.statusInProgress,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Buka Tugas Aktif', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tugas Tersedia', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '${availableTasks.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.navy),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tugas Saya', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '${myTasks.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.teal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section: Tugas Tersedia untuk Ditangani
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Laporan Siap Ditangani',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    if (availableTasks.isNotEmpty)
                      Text(
                        '${availableTasks.length} lokasi',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (availableTasks.isEmpty)
                  const EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'Tidak Ada Tugas Tersedia',
                    message: 'Semua laporan terverifikasi saat ini telah ditangani atau belum ada laporan baru.',
                  )
                else
                  ...availableTasks.map((report) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          report: report,
                          isAvailableTask: true,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.cleanerTaskDetail,
                              arguments: report.id,
                            );
                          },
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}
