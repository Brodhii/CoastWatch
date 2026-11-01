class AdminAuditLogModel {
  final String id;
  final DateTime timestamp;
  final String adminName;
  final String adminRole;
  final String actionType; // 'VERIFIKASI LAPORAN', 'TOLAK LAPORAN', 'TANDAI DUPLIKAT', 'NONAKTIFKAN AKUN', 'PERBARUI KATEGORI'
  final String targetId;
  final String targetLocation;
  final String summary;
  final String? coordinates;
  final String? hash;
  final String? warningBadge;
  final double? spatialDistanceMeters;
  final String? rejectionReason;

  const AdminAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.adminName,
    this.adminRole = 'Admin Operasional',
    required this.actionType,
    required this.targetId,
    required this.targetLocation,
    required this.summary,
    this.coordinates,
    this.hash,
    this.warningBadge,
    this.spatialDistanceMeters,
    this.rejectionReason,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      adminName: json['admin_name'] as String,
      adminRole: json['admin_role'] as String? ?? 'Admin Operasional',
      actionType: json['action_type'] as String,
      targetId: json['target_id'] as String,
      targetLocation: json['target_location'] as String,
      summary: json['summary'] as String,
      coordinates: json['coordinates'] as String?,
      hash: json['hash'] as String?,
      warningBadge: json['warning_badge'] as String?,
      spatialDistanceMeters: (json['spatial_distance_meters'] as num?)?.toDouble(),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'admin_name': adminName,
      'admin_role': adminRole,
      'action_type': actionType,
      'target_id': targetId,
      'target_location': targetLocation,
      'summary': summary,
      'coordinates': coordinates,
      'hash': hash,
      'warning_badge': warningBadge,
      'spatial_distance_meters': spatialDistanceMeters,
      'rejection_reason': rejectionReason,
    };
  }
}

