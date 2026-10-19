import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../services/report_service.dart';
import '../../../shared/app_button.dart';

class CreateReportReviewScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const CreateReportReviewScreen({super.key, required this.reportData});

  @override
  State<CreateReportReviewScreen> createState() => _CreateReportReviewScreenState();
}

class _CreateReportReviewScreenState extends State<CreateReportReviewScreen> {
  final ReportService _reportService = ReportService();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final photoFile = widget.reportData['photoFile'] as File;
      final categoryId = widget.reportData['categoryId'] as String;
      final categoryName = widget.reportData['categoryName'] as String;
      final description = widget.reportData['description'] as String;
      final latitude = widget.reportData['latitude'] as double;
      final longitude = widget.reportData['longitude'] as double;
      final accuracy = widget.reportData['accuracy'] as double;
      final photoTimestamp = widget.reportData['photoTimestamp'] as DateTime;
      final locationName = widget.reportData['locationName'] as String?;

      // Call ReportService to submit report with EXIF coordinates
      final createdReport = await _reportService.submitReport(
        photoFile: photoFile,
        categoryId: categoryId,
        categoryName: categoryName,
        description: description,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        photoTimestamp: photoTimestamp,
        locationName: locationName,
      );

      if (!mounted) return;

      // Navigate to Step 4 Success screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.createReportSuccess,
        (route) => route.isFirst,
        arguments: createdReport,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengiriman gagal: $e'),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoFile = widget.reportData['photoFile'] as File?;
    final categoryName = widget.reportData['categoryName'] as String? ?? '-';
    final description = widget.reportData['description'] as String? ?? '';
    final latitude = widget.reportData['latitude'] as double? ?? 0.0;
    final longitude = widget.reportData['longitude'] as double? ?? 0.0;
    final accuracy = widget.reportData['accuracy'] as double? ?? 0.0;
    final photoTimestamp = widget.reportData['photoTimestamp'] as DateTime?;
    final locationName = widget.reportData['locationName'] as String?;

    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    final coordsFormatted = '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langkah 3: Tinjau Laporan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(currentStep: 3),
            const SizedBox(height: 20),

            const Text(
              'Tinjau Rincian Sebelum Dikirim',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Periksa kembali foto bukti dan koordinat geotag Anda. Laporan akan ditinjau oleh Admin CoastWatch.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Photo Preview
            if (photoFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  photoFile,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // Summary Details Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('Kategori', categoryName, isBold: true),
                  if (locationName != null && locationName.isNotEmpty)
                    _buildReviewItem('Area Pesisir', locationName),
                  _buildReviewItem('Koordinat GPS', '$coordsFormatted (±${accuracy.toStringAsFixed(0)}m)'),
                  if (photoTimestamp != null)
                    _buildReviewItem(
                      'Waktu Foto',
                      DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(photoTimestamp),
                    ),
                  _buildReviewItem(
                    'Deskripsi',
                    description.isNotEmpty ? description : 'Tidak ada deskripsi tambahan',
                  ),
                  _buildReviewItem('Status Awal', 'Menunggu Verifikasi (Pending Review)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 20, color: AppTheme.navy),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identitas pelapor tidak ditampilkan pada peta publik. Hanya laporan yang terverifikasi Admin yang akan tampil sebagai marker publik.',
                      style: TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            AppButton(
              label: 'Kirim Laporan Geotag',
              onPressed: _isSubmitting ? null : _submitReport,
              isLoading: _isSubmitting,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      children: [
        _buildStepBadge(step: 1, label: 'Foto & Geotag', isActive: currentStep >= 1, isCurrent: currentStep == 1),
        Expanded(child: Container(height: 2, color: currentStep >= 2 ? AppTheme.navy : AppTheme.border)),
        _buildStepBadge(step: 2, label: 'Kategori', isActive: currentStep >= 2, isCurrent: currentStep == 2),
        Expanded(child: Container(height: 2, color: currentStep >= 3 ? AppTheme.navy : AppTheme.border)),
        _buildStepBadge(step: 3, label: 'Tinjau', isActive: currentStep >= 3, isCurrent: currentStep == 3),
      ],
    );
  }

  Widget _buildStepBadge({
    required int step,
    required String label,
    required bool isActive,
    required bool isCurrent,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppTheme.navy : AppTheme.border,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.white : AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
            color: isCurrent ? AppTheme.navy : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
