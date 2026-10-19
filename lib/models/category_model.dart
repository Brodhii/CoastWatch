import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int sortOrder;
  final IconData icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    this.sortOrder = 0,
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      icon: _getIconForCategory(json['id'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
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
      description: 'Botol, kantong kresek, kemasan sachet, styrofoam, dan fragmen plastik yang terlihat di pesisir.',
      sortOrder: 1,
      icon: Icons.water_drop_outlined,
    ),
    CategoryModel(
      id: 'household',
      name: 'Sampah rumah tangga/campuran',
      description: 'Sampah campuran rumah tangga yang menumpuk di garis pantai atau muara sungai.',
      sortOrder: 2,
      icon: Icons.delete_outline,
    ),
    CategoryModel(
      id: 'fishing',
      name: 'Alat tangkap dan limbah perikanan',
      description: 'Jaring terbengkalai (ghost net), tali tambang kapal, pelampung, atau alat tangkap rusak.',
      sortOrder: 3,
      icon: Icons.phishing,
    ),
    CategoryModel(
      id: 'liquid',
      name: 'Limbah cair atau indikasi pencemaran',
      description: 'Lapisan minyak, buih mencurigakan, atau perubahan warna air laut yang mencolok.',
      sortOrder: 4,
      icon: Icons.opacity,
    ),
    CategoryModel(
      id: 'organic',
      name: 'Sampah organik',
      description: 'Tumpukan sisa tumbuhan, kayu gelondongan hanyut, atau bahan organik yang mengotori pantai.',
      sortOrder: 5,
      icon: Icons.eco_outlined,
    ),
    CategoryModel(
      id: 'ecosystem',
      name: 'Kerusakan ekosistem pesisir',
      description: 'Indikasi kerusakan vegetasi mangrove, terumbu karang terdampar, atau abrasi abnormal.',
      sortOrder: 6,
      icon: Icons.forest_outlined,
    ),
    CategoryModel(
      id: 'other',
      name: 'Lainnya',
      description: 'Masalah pesisir di luar kategori utama (wajib menyertakan deskripsi rinci).',
      sortOrder: 7,
      icon: Icons.category_outlined,
    ),
  ];
}
