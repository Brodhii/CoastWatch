class CleanupTaskModel {
  final String id;
  final String reportId;
  final String cleanerId;
  final String? cleanerName;
  final String? notes;
  final double? cleanupLat;
  final double? cleanupLng;
  final DateTime? cleanupExifDateTimeOriginal;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status; // 'in_progress', 'completed'
  final String? afterPhotoUrl;
  final DateTime createdAt;

  const CleanupTaskModel({
    required this.id,
    required this.reportId,
    required this.cleanerId,
    this.cleanerName,
    this.notes,
    this.cleanupLat,
    this.cleanupLng,
    this.cleanupExifDateTimeOriginal,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.afterPhotoUrl,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  factory CleanupTaskModel.fromJson(Map<String, dynamic> json) {
    return CleanupTaskModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      cleanerId: json['cleaner_id'] as String,
      cleanerName: json['cleaner_name'] as String?,
      notes: json['notes'] as String?,
      cleanupLat: (json['cleanup_lat'] as num?)?.toDouble(),
      cleanupLng: (json['cleanup_lng'] as num?)?.toDouble(),
      cleanupExifDateTimeOriginal: json['cleanup_exif_datetime_original'] != null
          ? DateTime.parse(json['cleanup_exif_datetime_original'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      status: json['status'] as String? ?? 'in_progress',
      afterPhotoUrl: json['after_photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'cleaner_id': cleanerId,
      'cleaner_name': cleanerName,
      'notes': notes,
      'cleanup_lat': cleanupLat,
      'cleanup_lng': cleanupLng,
      'cleanup_exif_datetime_original': cleanupExifDateTimeOriginal?.toIso8601String(),
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
      'after_photo_url': afterPhotoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CleanupTaskModel copyWith({
    String? id,
    String? reportId,
    String? cleanerId,
    String? cleanerName,
    String? notes,
    double? cleanupLat,
    double? cleanupLng,
    DateTime? cleanupExifDateTimeOriginal,
    DateTime? startedAt,
    DateTime? completedAt,
    String? status,
    String? afterPhotoUrl,
    DateTime? createdAt,
  }) {
    return CleanupTaskModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      cleanerId: cleanerId ?? this.cleanerId,
      cleanerName: cleanerName ?? this.cleanerName,
      notes: notes ?? this.notes,
      cleanupLat: cleanupLat ?? this.cleanupLat,
      cleanupLng: cleanupLng ?? this.cleanupLng,
      cleanupExifDateTimeOriginal: cleanupExifDateTimeOriginal ?? this.cleanupExifDateTimeOriginal,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
