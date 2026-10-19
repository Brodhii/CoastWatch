import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../models/category_model.dart';
import '../../../shared/app_button.dart';
import '../../../shared/app_text_field.dart';
import '../widgets/category_selector.dart';

class CreateReportFormScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const CreateReportFormScreen({super.key, required this.reportData});

  @override
  State<CreateReportFormScreen> createState() => _CreateReportFormScreenState();
}

class _CreateReportFormScreenState extends State<CreateReportFormScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();

  CategoryModel? _selectedCategory;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = CategoryModel.defaultCategories.first;
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Harap pilih satu kategori masalah pesisir.';
      });
      return;
    }

    if (_selectedCategory!.id == 'other' && _descController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Kategori "Lainnya" wajib menyertakan deskripsi penjelasan.';
      });
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.createReportReview,
      arguments: {
        ...widget.reportData,
        'categoryId': _selectedCategory!.id,
        'categoryName': _selectedCategory!.name,
        'description': _descController.text.trim(),
        'locationName': _locationNameController.text.trim().isNotEmpty
            ? _locationNameController.text.trim()
            : null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Langkah 2: Kategori & Deskripsi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(currentStep: 2),
            const SizedBox(height: 20),

            const Text(
              'Pilih Kategori Masalah Pesisir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih kategori yang paling sesuai dengan bukti foto Anda.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            CategorySelector(
              categories: CategoryModel.defaultCategories,
              selectedCategoryId: _selectedCategory?.id,
              onCategorySelected: (cat) {
                setState(() {
                  _selectedCategory = cat;
                  _errorMessage = null;
                });
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              'Informasi Tambahan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Nama Area / Patokan Pesisir (Opsional)',
              hint: 'Contoh: Pantai Trikora, dekat mercusuar',
              controller: _locationNameController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Deskripsi Temuan',
              hint: 'Jelaskan temuan dan kondisi lokasi...',
              controller: _descController,
              maxLines: 4,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.statusRejectedBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppTheme.statusRejected),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.statusRejected),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            AppButton(
              label: 'Lanjut ke Tinjau Laporan',
              onPressed: _onNext,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
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
