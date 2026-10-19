import '../core/constants.dart';

class UserProfileModel {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isGuest => role == UserRole.guest;
  bool get isReporter => role == UserRole.reporter;
  bool get isCleaner => role == UserRole.cleaner;
  bool get isAdmin => role == UserRole.admin;

  factory UserProfileModel.guest() {
    return UserProfileModel(
      id: 'guest',
      email: '',
      displayName: 'Pengunjung',
      role: UserRole.guest,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Pengguna',
      role: UserRoleExtension.fromString(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role.value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
