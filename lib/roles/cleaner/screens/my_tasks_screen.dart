import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/report_service.dart';
import '../../../shared/empty_state_view.dart';
import '../widgets/task_card.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final ReportService _reportService = ReportService();
  ReportStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reportService,
      builder: (context, _) {
        final allMyTasks = _reportService.getMyTasks();
        final filteredTasks = _filterStatus == null
            ? allMyTasks
            : allMyTasks.where((t) => t.status == _filterStatus).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tugas Saya'),
          ),
          body: Column(
            children: [
              // Filter Chips
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppTheme.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Semua (${allMyTasks.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sedang Ditangani', ReportStatus.inProgress),
                    const SizedBox(width: 8),
                    _buildFilterChip('Selesai Dibersihkan', ReportStatus.cleaned),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: filteredTasks.isEmpty
                    ? EmptyStateView(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Belum Ada Tugas Aktif',
                        message: 'Anda belum mengambil tugas pembersihan pesisir. Buka daftar tugas tersedia untuk mengambil aksi.',
                        buttonLabel: 'Cari Tugas Tersedia',
                        onButtonPressed: () {
                          Navigator.pushNamed(context, AppRoutes.initial);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final taskReport = filteredTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TaskCard(
                              report: taskReport,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.cleanerTaskDetail,
                                  arguments: taskReport.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ReportStatus? status) {
    final isSelected = _filterStatus == status;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.navy : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
