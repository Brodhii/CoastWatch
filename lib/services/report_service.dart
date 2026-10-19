import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/cleanup_task_model.dart';
import '../models/report_model.dart';
import '../models/status_history_model.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'mock_data_service.dart';

class ReportService extends ChangeNotifier {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal() {
    _reports = MockDataService.getInitialMockReports();
  }

  final AuthService _authService = AuthService();
  final _uuid = const Uuid();

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => List.unmodifiable(_reports);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetch public reports (Strictly verified only on public map as per Desain.md Section 6.4 & 15.5)
  List<ReportModel> getPublicReports({String? categoryId, DateTimeRange? dateRange}) {
    return _reports.where((r) {
      if (!r.isPubliclyVisible) return false;
      if (categoryId != null && categoryId.isNotEmpty && r.categoryId != categoryId) {
        return false;
      }
      if (dateRange != null) {
        if (r.createdAt.isBefore(dateRange.start) || r.createdAt.isAfter(dateRange.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Get reports created by the currently logged-in reporter
  List<ReportModel> getMyReports() {
    final user = _authService.currentUser;
    if (user.isGuest) return [];
    return _reports.where((r) => r.reporterId == user.id || r.reporterName == user.displayName).toList();
  }

  /// Get verified reports available for cleaners to claim (Desain.md Section 6.5 & 8.7)
  List<ReportModel> getAvailableTasks() {
    return _reports.where((r) => r.isAvailableForCleanup).toList();
  }

  /// Get tasks currently claimed or completed by current cleaner
  List<ReportModel> getMyTasks() {
    final user = _authService.currentUser;
    if (user.isGuest) return [];
    return _reports.where((r) => r.cleanupTask?.cleanerId == user.id).toList();
  }

  /// Get single report by ID
  ReportModel? getReportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Submit new report with verified geotag (Desain.md Section 6.2 & 15.6)
  Future<ReportModel> submitReport({
    required File photoFile,
    required String categoryId,
    required String categoryName,
    required String description,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime photoTimestamp,
    String? locationName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Server-side / local validation check
      if (!LocationService.validateCoordinates(latitude, longitude)) {
        throw Exception('Koordinat GPS tidak valid (lat: $latitude, lng: $longitude).');
      }

      final now = DateTime.now();
      final reportNum = (_reports.length + 1).toString().padLeft(3, '0');
      final reportId = 'CW-${now.year}-$reportNum';
      final currentUser = _authService.currentUser;

      // Note: In local/demo mode or real mode, use the local file path or uploaded URL
      final photoUrl = photoFile.path;

      final newReport = ReportModel(
        id: reportId,
        clientSubmissionId: _uuid.v4(),
        reporterId: currentUser.id,
        reporterName: currentUser.displayName,
        categoryId: categoryId,
        categoryName: categoryName,
        description: description.trim(),
        latitude: latitude,
        longitude: longitude,
        locationName: locationName ?? 'Pesisir Indonesia (GPS Terverifikasi)',
        exifDateTimeOriginal: photoTimestamp,
        deviceLocationAccuracyM: accuracy,
        metadataValidationStatus: accuracy <= AppConstants.maxAccuracyThresholdMeters ? 'valid' : 'warning',
        status: ReportStatus.pendingReview, // Initial status is ALWAYS pending_review
        visibility: 'private',
        beforePhotoUrl: photoUrl,
        createdAt: now,
        updatedAt: now,
        statusHistory: [
          StatusHistoryModel(
            id: 'sh-${_uuid.v4()}',
            reportId: reportId,
            fromStatus: null,
            toStatus: ReportStatus.pendingReview,
            actorName: currentUser.displayName,
            reason: 'Laporan baru diajukan melalui aplikasi mobile dengan bukti geotag valid',
            createdAt: now,
          ),
        ],
      );

      _reports.insert(0, newReport);
      _isLoading = false;
      notifyListeners();
      return newReport;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Cleaner claims a verified task (Desain.md Section 6.5)
  Future<bool> claimTask(String reportId, {String? notes}) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    if (report.status != ReportStatus.verified || report.cleanupTask != null) {
      throw Exception('Tugas ini sudah diambil oleh relawan lain atau tidak tersedia.');
    }

    final user = _authService.currentUser;
    final now = DateTime.now();
    final task = CleanupTaskModel(
      id: 'tsk-${_uuid.v4()}',
      reportId: reportId,
      cleanerId: user.id,
      cleanerName: user.displayName,
      notes: notes ?? 'Tugas pembersihan diambil.',
      startedAt: now,
      status: 'in_progress',
      createdAt: now,
    );

    final updatedReport = report.copyWith(
      status: ReportStatus.inProgress,
      cleanupTask: task,
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: ReportStatus.verified,
          toStatus: ReportStatus.inProgress,
          actorName: user.displayName,
          reason: 'Tugas pembersihan diklaim oleh relawan',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;
    notifyListeners();
    return true;
  }

  /// Cleaner completes a task with after-photo geotag proof (Desain.md Section 6.5 & 8.7)
  Future<bool> completeCleanupTask({
    required String reportId,
    required File proofPhotoFile,
    required String notes,
    required double cleanupLat,
    required double cleanupLng,
    required DateTime cleanupTimestamp,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final user = _authService.currentUser;

    if (report.cleanupTask == null || report.cleanupTask?.cleanerId != user.id) {
      throw Exception('Anda bukan pemegang sah dari tugas pembersihan ini.');
    }

    if (!LocationService.validateCoordinates(cleanupLat, cleanupLng)) {
      throw Exception('Foto bukti pembersihan tidak memiliki koordinat GPS yang sah.');
    }

    final now = DateTime.now();
    final proofUrl = proofPhotoFile.path;

    final updatedTask = report.cleanupTask!.copyWith(
      notes: notes.trim(),
      cleanupLat: cleanupLat,
      cleanupLng: cleanupLng,
      cleanupExifDateTimeOriginal: cleanupTimestamp,
      completedAt: now,
      status: 'completed',
      afterPhotoUrl: proofUrl,
    );

    final updatedReport = report.copyWith(
      status: ReportStatus.cleaned,
      afterPhotoUrl: proofUrl,
      cleanupTask: updatedTask,
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: ReportStatus.inProgress,
          toStatus: ReportStatus.cleaned,
          actorName: user.displayName,
          reason: 'Pembersihan selesai dengan unggahan bukti foto geotag sesudah pembersihan',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;
    notifyListeners();
    return true;
  }
}
