import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../models/report_model.dart';
import '../../../shared/app_button.dart';
import '../../../shared/status_badge.dart';

class CleanupSuccessScreen extends StatelessWidget {
  final ReportModel? report;

  const CleanupSuccessScreen({super.key, this.report});

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
                  Icons.task_alt_rounded,
                  size: 56,
                  color: AppTheme.statusCleaned,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Bukti Pembersihan Berhasil Dikirim',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'Bukti foto ber-geotag sesudah pembersihan telah dikirimkan ke Admin Operasional. Status laporan kini dalam tahap Validasi Akhir sebelum disahkan sebagai Pantai Bersih.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              if (report != null)
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
                      Text(
                        report!.categoryName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy),
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(status: report!.status == ReportStatus.cleaned ? ReportStatus.cleaned : ReportStatus.pendingCleanupReview),
                      const SizedBox(height: 8),
                      Text(
                        report!.locationName != null && report!.locationName!.isNotEmpty
                            ? report!.locationName!
                            : 'Kawasan Pesisir Pantai Batam',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              AppButton(
                label: 'Kembali ke Dasbor Relawan',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false,
                  );
                },
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
