import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import 'app_button.dart';

class GuestPromptDialog extends StatelessWidget {
  final String actionTitle;
  final String actionDescription;

  const GuestPromptDialog({
    super.key,
    this.actionTitle = 'Memerlukan Akun',
    this.actionDescription = 'Fitur ini membutuhkan akun terdaftar untuk memastikan akuntabilitas laporan geotag dan pelacakan status penanganan.',
  });

  static Future<void> show(BuildContext context, {String? title, String? description}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestPromptDialog(
        actionTitle: title ?? 'Memerlukan Akun',
        actionDescription: description ?? 'Fitur ini membutuhkan akun terdaftar untuk memastikan akuntabilitas laporan geotag dan pelacakan status penanganan.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            actionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            actionDescription,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Masuk Akun',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Daftar Akun Baru',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.register);
            },
            variant: AppButtonVariant.outlined,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tetap sebagai Pengunjung',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
