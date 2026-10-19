import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../services/report_service.dart';
import '../../../shared/empty_state_view.dart';
import '../widgets/task_card.dart';

class AvailableTasksScreen extends StatelessWidget {
  const AvailableTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();

    return ListenableBuilder(
      listenable: reportService,
      builder: (context, _) {
        final availableTasks = reportService.getAvailableTasks();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tugas Tersedia'),
          ),
          body: availableTasks.isEmpty
              ? const EmptyStateView(
                  icon: Icons.check_circle_outline,
                  title: 'Tidak Ada Tugas Tersedia',
                  message: 'Saat ini semua laporan pesisir yang terverifikasi telah diambil oleh relawan atau belum ada laporan baru.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableTasks.length,
                  itemBuilder: (context, index) {
                    final report = availableTasks[index];
                    return Padding(
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
                    );
                  },
                ),
        );
      },
    );
  }
}
