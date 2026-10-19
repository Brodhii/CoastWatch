import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_service.dart';
import '../../../shared/empty_state_view.dart';
import '../../../shared/guest_prompt_dialog.dart';
import '../../../shared/report_card.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();

  ReportStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_authService, _reportService]),
      builder: (context, _) {
        if (_authService.isGuest) {
          return Scaffold(
            appBar: AppBar(title: const Text('Laporan Saya')),
            body: EmptyStateView(
              icon: Icons.lock_outline,
              title: 'Akses Memerlukan Akun',
              message: 'Masuk atau daftar untuk melihat riwayat laporan dan status verifikasi laporan Anda.',
              buttonLabel: 'Masuk Akun',
              onButtonPressed: () {
                GuestPromptDialog.show(
                  context,
                  title: 'Akses Laporan Saya',
                  description: 'Silakan masuk untuk melihat daftar laporan yang pernah Anda kirimkan.',
                );
              },
            ),
          );
        }

        final myReports = _reportService.getMyReports();
        final filteredReports = _filterStatus == null
            ? myReports
            : myReports.where((r) => r.status == _filterStatus).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Laporan Saya'),
            actions: [
              IconButton(
                tooltip: 'Buat Laporan Baru',
                icon: const Icon(Icons.add, size: 22),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createReportCamera);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Status Filter Tabs
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppTheme.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Semua (${myReports.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Menunggu Verifikasi', ReportStatus.pendingReview),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terverifikasi', ReportStatus.verified),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sedang Ditangani', ReportStatus.inProgress),
                    const SizedBox(width: 8),
                    _buildFilterChip('Selesai', ReportStatus.cleaned),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ditolak', ReportStatus.rejected),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Reports List or Empty State
              Expanded(
                child: filteredReports.isEmpty
                    ? EmptyStateView(
                        icon: Icons.assignment_outlined,
                        title: _filterStatus == null ? 'Belum Ada Laporan' : 'Tidak Ada Laporan dengan Status Ini',
                        message: _filterStatus == null
                            ? 'Anda belum pernah mengirimkan laporan temuan pesisir.'
                            : 'Coba pilih filter status lainnya untuk melihat riwayat laporan Anda.',
                        buttonLabel: _filterStatus == null ? 'Buat Laporan Pertama' : null,
                        onButtonPressed: _filterStatus == null
                            ? () => Navigator.pushNamed(context, AppRoutes.createReportCamera)
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReportCard(
                              report: report,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.myReportDetail,
                                  arguments: report.id,
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
