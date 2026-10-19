import '../core/constants.dart';
import 'cleanup_task_model.dart';
import 'status_history_model.dart';

class ReportModel {
  final String id;
  final String? clientSubmissionId;
  final String reporterId;
  final String? reporterName;
  final String categoryId;
  final String categoryName;
  final String description;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime? exifDateTimeOriginal;
  final double? deviceLocationAccuracyM;
  final String metadataValidationStatus; // 'valid', 'warning', 'invalid'
  final ReportStatus status;
  final String? duplicateOf;
  final String visibility; // 'public', 'private'
  final String beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? rejectionReason;
  final CleanupTaskModel? cleanupTask;
  final List<StatusHistoryModel> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    required this.id,
    this.clientSubmissionId,
    required this.reporterId,
    this.reporterName,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.exifDateTimeOriginal,
    this.deviceLocationAccuracyM,
    this.metadataValidationStatus = 'valid',
    required this.status,
    this.duplicateOf,
    this.visibility = 'public',
    required this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.rejectionReason,
    this.cleanupTask,
    this.statusHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPubliclyVisible => status == ReportStatus.verified && visibility == 'public';
  bool get isAvailableForCleanup => status == ReportStatus.verified && cleanupTask == null;
  bool get isInProgress => status == ReportStatus.inProgress;
  bool get isCleaned => status == ReportStatus.cleaned;
  bool get isPendingReview => status == ReportStatus.pendingReview;

  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir';
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      clientSubmissionId: json['client_submission_id'] as String?,
      reporterId: json['reporter_id'] as String? ?? 'anonymous',
      reporterName: json['reporter_name'] as String?,
      categoryId: json['category_id'] as String? ?? 'other',
      categoryName: json['category_name'] as String? ?? 'Lainnya',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'] as String?,
      exifDateTimeOriginal: json['exif_datetime_original'] != null
          ? DateTime.parse(json['exif_datetime_original'] as String)
          : null,
      deviceLocationAccuracyM: (json['device_location_accuracy_m'] as num?)?.toDouble(),
      metadataValidationStatus: json['metadata_validation_status'] as String? ?? 'valid',
      status: ReportStatusExtension.fromString(json['status'] as String?),
      duplicateOf: json['duplicate_of'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      beforePhotoUrl: json['before_photo_url'] as String? ?? '',
      afterPhotoUrl: json['after_photo_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      cleanupTask: json['cleanup_task'] != null
          ? CleanupTaskModel.fromJson(json['cleanup_task'] as Map<String, dynamic>)
          : null,
      statusHistory: json['status_history'] != null
          ? (json['status_history'] as List)
              .map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_submission_id': clientSubmissionId,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'exif_datetime_original': exifDateTimeOriginal?.toIso8601String(),
      'device_location_accuracy_m': deviceLocationAccuracyM,
      'metadata_validation_status': metadataValidationStatus,
      'status': status.value,
      'duplicate_of': duplicateOf,
      'visibility': visibility,
      'before_photo_url': beforePhotoUrl,
      'after_photo_url': afterPhotoUrl,
      'rejection_reason': rejectionReason,
      'cleanup_task': cleanupTask?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? clientSubmissionId,
    String? reporterId,
    String? reporterName,
    String? categoryId,
    String? categoryName,
    String? description,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? exifDateTimeOriginal,
    double? deviceLocationAccuracyM,
    String? metadataValidationStatus,
    ReportStatus? status,
    String? duplicateOf,
    String? visibility,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
    String? rejectionReason,
    CleanupTaskModel? cleanupTask,
    List<StatusHistoryModel>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      clientSubmissionId: clientSubmissionId ?? this.clientSubmissionId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      exifDateTimeOriginal: exifDateTimeOriginal ?? this.exifDateTimeOriginal,
      deviceLocationAccuracyM: deviceLocationAccuracyM ?? this.deviceLocationAccuracyM,
      metadataValidationStatus: metadataValidationStatus ?? this.metadataValidationStatus,
      status: status ?? this.status,
      duplicateOf: duplicateOf ?? this.duplicateOf,
      visibility: visibility ?? this.visibility,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cleanupTask: cleanupTask ?? this.cleanupTask,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
