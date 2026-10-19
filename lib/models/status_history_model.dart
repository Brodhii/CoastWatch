import '../core/constants.dart';

class StatusHistoryModel {
  final String id;
  final String reportId;
  final ReportStatus? fromStatus;
  final ReportStatus toStatus;
  final String? actorId;
  final String? actorName;
  final String? reason;
  final DateTime createdAt;

  const StatusHistoryModel({
    required this.id,
    required this.reportId,
    this.fromStatus,
    required this.toStatus,
    this.actorId,
    this.actorName,
    this.reason,
    required this.createdAt,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      fromStatus: json['from_status'] != null
          ? ReportStatusExtension.fromString(json['from_status'] as String)
          : null,
      toStatus: ReportStatusExtension.fromString(json['to_status'] as String),
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'from_status': fromStatus?.value,
      'to_status': toStatus.value,
      'actor_id': actorId,
      'actor_name': actorName,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
