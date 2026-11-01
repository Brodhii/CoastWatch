import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int sortOrder;
  final IconData icon;
  final String code;
  final int reportCount;
  final String? updatedDate;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    this.sortOrder = 0,
    required this.icon,
    this.code = 'CW-CAT-00',
    this.reportCount = 0,
    this.updatedDate,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      icon: _getIconForCategory(json['id'] as String),
      code: json['code'] as String? ?? 'CW-CAT-00',
      reportCount: json['report_count'] as int? ?? 0,
      updatedDate: json['updated_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
      'code': code,
      'report_count': reportCount,
      'updated_date': updatedDate,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    int? sortOrder,
    IconData? icon,
    String? code,
    int? reportCount,
    String? updatedDate,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      icon: icon ?? this.icon,
      code: code ?? this.code,
      reportCount: reportCount ?? this.reportCount,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  static IconData _getIconForCategory(String id) {
    switch (id.toLowerCase()) {
      case 'plastic':
        return Icons.water_drop_outlined;
      case 'household':
        return Icons.delete_outline;
      case 'fishing':
        return Icons.phishing;
      case 'liquid':
        return Icons.opacity;
      case 'organic':
        return Icons.eco_outlined;
      case 'ecosystem':
        return Icons.forest_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  static List<CategoryModel> get defaultCategories => const [
    CategoryModel(
      id: 'plastic',
      name: 'Sampah plastik',
      description: 'Botol, kemasan sachet, kresek jeriken, dan limbah polimer di bibir pantai/muara.',
      sortOrder: 1,
      icon: Icons.water_drop_outlined,
      code: 'CW-CAT-01',
      reportCount: 81,
      updatedDate: '18 Okt 2026 09:20',
    ),
    CategoryModel(
      id: 'household',
      name: 'Sampah rumah tangga/campuran',
      description: 'Kain, perabot rusak, kaca, residu domestik, puntung rokok.',
      sortOrder: 2,
      icon: Icons.delete_outline,
      code: 'CW-CAT-02',
      reportCount: 17,
      updatedDate: '12 Okt 2026 14:15',
    ),
    CategoryModel(
      id: 'fishing',
      name: 'Alat tangkap dan limbah perikanan',
      description: 'Jaring hantu (ghost nets), pelampung busa, senar pancing kusut.',
      sortOrder: 3,
      icon: Icons.phishing,
      code: 'CW-CAT-03',
      reportCount: 37,
      updatedDate: '04 Okt 2026 11:02',
    ),
    CategoryModel(
      id: 'liquid',
      name: 'Limbah cair atau indikasi pencemaran',
      description: 'Ceceran oli, lapisan solar, air berminyak, busa kimia di perairan pesisir.',
      sortOrder: 4,
      icon: Icons.opacity,
      code: 'CW-CAT-04',
      reportCount: 27,
      updatedDate: '29 Sep 2026 16:48',
    ),
    CategoryModel(
      id: 'organic',
      name: 'Sampah organik',
      description: 'Kayu gelondongan hanyut, bangkai biota laut, tumpukan vegetasi laut.',
      sortOrder: 5,
      icon: Icons.eco_outlined,
      code: 'CW-CAT-05',
      reportCount: 12,
      updatedDate: '22 Sep 2026 08:30',
    ),
    CategoryModel(
      id: 'ecosystem',
      name: 'Kerusakan ekosistem pesisir',
      description: 'Pohon bakau roboh akibat abrasi, kerusakan terumbu, tebing pantai tergerus.',
      sortOrder: 6,
      icon: Icons.forest_outlined,
      code: 'CW-CAT-06',
      reportCount: 6,
      updatedDate: '15 Sep 2026 13:10',
    ),
    CategoryModel(
      id: 'other',
      name: 'Lainnya',
      description: 'Temuan material pesisir yang belum teridentifikasi dalam klasifikasi di atas.',
      sortOrder: 7,
      icon: Icons.category_outlined,
      code: 'CW-CAT-07',
      reportCount: 4,
      updatedDate: '01 Sep 2026 10:00',
    ),
  ];
}
