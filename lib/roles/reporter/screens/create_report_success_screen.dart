import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../models/report_model.dart';
import '../../../shared/app_button.dart';
import '../../../shared/status_badge.dart';

class CreateReportSuccessScreen extends StatelessWidget {
  final ReportModel report;

  const CreateReportSuccessScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.statusCleanedBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppTheme.statusCleaned,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Laporan Berhasil Diajukan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'Bukti foto dan koordinat geotag Anda telah berhasil disimpan dan diteruskan ke antrean verifikasi Admin.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Report ID & Status Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Nomor Laporan',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.id,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatusBadge(status: report.status),
                    const SizedBox(height: 10),
                    Text(
                      report.locationName ?? report.formattedCoordinates,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              AppButton(
                label: 'Lihat Status di Laporan Saya',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false,
                  );
                },
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Kembali ke Beranda',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false,
                  );
                },
                variant: AppButtonVariant.outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
