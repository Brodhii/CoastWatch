class AdminUserModel {
  final String id; // e.g. '#PLP-8821'
  final String name;
  final String maskedEmail;
  final String primaryRegion;
  final DateTime joinedDate;
  final int validReportsCount;
  final int rejectedReportsCount;
  final double validityRate; // 0.0 - 1.0 (e.g. 0.80)
  final bool isVerifiedRelawan;
  final bool isSuspended;
  final String? statusNote;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.maskedEmail,
    required this.primaryRegion,
    required this.joinedDate,
    required this.validReportsCount,
    required this.rejectedReportsCount,
    required this.validityRate,
    this.isVerifiedRelawan = false,
    this.isSuspended = false,
    this.statusNote,
  });

  int get totalReports => validReportsCount + rejectedReportsCount;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      maskedEmail: json['masked_email'] as String,
      primaryRegion: json['primary_region'] as String,
      joinedDate: DateTime.parse(json['joined_date'] as String),
      validReportsCount: json['valid_reports_count'] as int? ?? 0,
      rejectedReportsCount: json['rejected_reports_count'] as int? ?? 0,
      validityRate: (json['validity_rate'] as num?)?.toDouble() ?? 0.0,
      isVerifiedRelawan: json['is_verified_relawan'] as bool? ?? false,
      isSuspended: json['is_suspended'] as bool? ?? false,
      statusNote: json['status_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'masked_email': maskedEmail,
      'primary_region': primaryRegion,
      'joined_date': joinedDate.toIso8601String(),
      'valid_reports_count': validReportsCount,
      'rejected_reports_count': rejectedReportsCount,
      'validity_rate': validityRate,
      'is_verified_relawan': isVerifiedRelawan,
      'is_suspended': isSuspended,
      'status_note': statusNote,
    };
  }

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? maskedEmail,
    String? primaryRegion,
    DateTime? joinedDate,
    int? validReportsCount,
    int? rejectedReportsCount,
    double? validityRate,
    bool? isVerifiedRelawan,
    bool? isSuspended,
    String? statusNote,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      primaryRegion: primaryRegion ?? this.primaryRegion,
      joinedDate: joinedDate ?? this.joinedDate,
      validReportsCount: validReportsCount ?? this.validReportsCount,
      rejectedReportsCount: rejectedReportsCount ?? this.rejectedReportsCount,
      validityRate: validityRate ?? this.validityRate,
      isVerifiedRelawan: isVerifiedRelawan ?? this.isVerifiedRelawan,
      isSuspended: isSuspended ?? this.isSuspended,
      statusNote: statusNote ?? this.statusNote,
    );
  }
}

