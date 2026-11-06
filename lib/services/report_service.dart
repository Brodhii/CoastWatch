import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/admin_audit_log_model.dart';
import '../models/admin_user_model.dart';
import '../models/category_model.dart';
import '../models/cleanup_task_model.dart';
import '../models/report_model.dart';
import '../models/status_history_model.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';

class ReportService extends ChangeNotifier {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal() {
    _reports = MockDataService.getInitialMockReports();
    _auditLogs = MockDataService.getInitialAuditLogs();
    _adminUsers = MockDataService.getInitialAdminUsers();
    _categories = List.from(CategoryModel.defaultCategories);
  }

  final AuthService _authService = AuthService();
  final _uuid = const Uuid();

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => List.unmodifiable(_reports);

  List<AdminAuditLogModel> _auditLogs = [];
  List<AdminAuditLogModel> get auditLogs => List.unmodifiable(_auditLogs);

  List<AdminUserModel> _adminUsers = [];
  List<AdminUserModel> get adminUsers => List.unmodifiable(_adminUsers);

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inisialisasi sinkronisasi data dari cloud Supabase saat aplikasi terbuka
  Future<void> init() async {
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        final catData = await client
            .from('report_categories')
            .select()
            .eq('is_active', true);
        if (catData.isNotEmpty) {
          _categories = (catData as List)
              .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList();
          debugPrint('[ReportService] Synced ${_categories.length} categories from Supabase cloud.');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ReportService] Category sync note: $e');
      }

      // 2. Reports
      try {
        final reportsData = await client
            .from('reports')
            .select()
            .order('created_at', ascending: false);
        if (reportsData.isNotEmpty) {
          final liveReports = (reportsData as List).map((r) {
            final cat = _categories.firstWhere(
              (c) => c.id == r['category_id'],
              orElse: () => CategoryModel.defaultCategories.first,
            );
            return ReportModel.fromJson({
              ...r,
              'category_name': cat.name,
              'before_photo_url': r['before_photo_url'] ?? '',
            });
          }).toList();
          _reports = liveReports;
          debugPrint('[ReportService] Synced ${liveReports.length} reports from Supabase cloud.');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ReportService] Reports sync note: $e');
      }

      // 3. Profiles / Admin Users
      try {
        final profilesData = await client
            .from('profiles')
            .select()
            .order('created_at', ascending: false);
        if (profilesData.isNotEmpty) {
          final liveUsers = (profilesData as List).map((p) {
            final role = p['role'] as String? ?? 'reporter';
            return AdminUserModel(
              id: p['id'] as String,
              name: p['display_name'] as String? ?? 'Pengguna',
              maskedEmail: '${(p['display_name'] as String? ?? 'user').toLowerCase().replaceAll(' ', '.')}@coastwatch.id',
              primaryRegion: role == 'cleaner' ? 'Relawan Pesisir' : (role == 'admin' ? 'Admin Operasional' : 'Pelapor Warga'),
              joinedDate: DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now(),
              validReportsCount: 0,
              rejectedReportsCount: 0,
              validityRate: 1.0,
              isVerifiedRelawan: role == 'cleaner',
              isSuspended: !(p['is_active'] as bool? ?? true),
            );
          }).toList();
          _adminUsers = liveUsers;
          debugPrint('[ReportService] Synced ${_adminUsers.length} profiles from Supabase cloud.');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ReportService] Profiles sync note: $e');
      }

      // 4. Audit Logs
      try {
        final logsData = await client
            .from('audit_logs')
            .select()
            .order('created_at', ascending: false);
        if (logsData.isNotEmpty) {
          final liveLogs = (logsData as List).map((l) {
            final target = l['target_id'] != null
                ? '#${l['target_id'].toString().substring(0, 8)}'
                : '-';
            return AdminAuditLogModel(
              id: l['id'] as String,
              timestamp: DateTime.tryParse(l['created_at'] as String? ?? '') ?? DateTime.now(),
              adminName: 'Admin',
              actionType: l['action'] as String? ?? 'AUDIT',
              targetId: target,
              targetLocation: 'Pesisir Lapangan',
              summary: 'Aktivitas audit tercatat di database Supabase',
            );
          }).toList();
          _auditLogs = liveLogs;
          debugPrint('[ReportService] Synced ${_auditLogs.length} audit logs from Supabase cloud.');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ReportService] Audit log sync note: $e');
      }
    }
  }

  // ================= ADMIN COUNTS & STATS =================
  int get pendingReportsCount => _reports.where((r) => r.status == ReportStatus.pendingReview).length;
  int get verifiedReportsCount => _reports.where((r) => r.status == ReportStatus.verified).length;
  int get rejectedReportsCount => _reports.where((r) => r.status == ReportStatus.rejected).length;
  int get duplicateReportsCount => _reports.where((r) => r.status == ReportStatus.duplicate).length;
  int get totalReportsCount => _reports.length;

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
      final reportId = _uuid.v4();
      final currentUser = _authService.currentUser;

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

      // Sinkronkan ke database Supabase jika online & terautentikasi
      final client = SupabaseService().client;
      if (client != null && SupabaseService().isInitialized && _authService.isAuthenticated) {
        try {
          await client.from('reports').insert({
            'id': reportId,
            'client_submission_id': newReport.clientSubmissionId,
            'reporter_id': currentUser.id,
            'category_id': categoryId,
            'description': description.trim(),
            'latitude': latitude,
            'longitude': longitude,
            'exif_datetime_original': photoTimestamp.toIso8601String(),
            'device_location_accuracy_m': accuracy,
            'status': newReport.status.value,
          });
          debugPrint('[ReportService] Report successfully saved to Supabase cloud!');
        } catch (e) {
          debugPrint('[ReportService] Supabase insert note: $e');
        }
      }
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

  // ================= ADMIN DECISIONS (Desain.md Section 6.3 & 15.11) =================

  /// Admin verifies a report to publish on public GIS map
  Future<bool> adminVerifyReport(String reportId, {String? notes}) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Budi Santoso';

    final updatedReport = report.copyWith(
      status: ReportStatus.verified,
      visibility: 'public',
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: ReportStatus.verified,
          actorName: '$adminName (Admin Operasional)',
          reason: notes ?? 'Laporan disetujui untuk ditampilkan ke peta publik. Metadata EXIF GPS valid dan bukti visual sampah terkonfirmasi.',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;

    // Append to audit log
    _auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'aud-${_uuid.v4()}',
        timestamp: now,
        adminName: adminName,
        actionType: 'VERIFIKASI LAPORAN',
        targetId: '#${report.id}',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Laporan disetujui untuk ditampilkan ke peta publik. Metadata EXIF GPS valid (±${report.deviceLocationAccuracyM?.toStringAsFixed(1) ?? '4.0'}m).',
        coordinates: '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
        hash: 'sha256-${report.id.toLowerCase()}',
      ),
    );

    // Sinkronisasi status verifikasi ke cloud Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'status': 'verified',
        }).eq('id', reportId);

        if (_authService.isAuthenticated) {
          await client.from('report_reviews').insert({
            'report_id': reportId,
            'admin_id': adminUser.id,
            'decision': 'verified',
            'notes': notes ?? 'Verifikasi disetujui admin',
          });
          await client.from('audit_logs').insert({
            'actor_id': adminUser.id,
            'action': 'VERIFIKASI LAPORAN',
            'target_id': reportId,
          });
        }
        debugPrint('[ReportService] adminVerifyReport berhasil disinkronkan ke Supabase cloud.');
      } catch (e) {
        debugPrint('[ReportService] Supabase verify sync note: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Admin rejects a report with MANDATORY reason (Desain.md Section 6.3 & 15.11)
  Future<bool> adminRejectReport(String reportId, {required String reason}) async {
    if (reason.trim().isEmpty) {
      throw Exception('Alasan penolakan laporan wajib diisi secara transparan.');
    }

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Budi Santoso';

    final updatedReport = report.copyWith(
      status: ReportStatus.rejected,
      visibility: 'private',
      rejectionReason: reason.trim(),
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: ReportStatus.rejected,
          actorName: '$adminName (Admin Operasional)',
          reason: reason.trim(),
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;

    // Append to audit log
    _auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'aud-${_uuid.v4()}',
        timestamp: now,
        adminName: adminName,
        actionType: 'TOLAK LAPORAN',
        targetId: '#${report.id}',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Alasan: ${reason.trim()}',
        rejectionReason: reason.trim(),
        warningBadge: 'Ditolak Admin',
        hash: 'sha256-rej-${report.id.toLowerCase()}',
      ),
    );

    // Sinkronisasi status tolak ke cloud Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'status': 'rejected',
        }).eq('id', reportId);

        if (_authService.isAuthenticated) {
          await client.from('report_reviews').insert({
            'report_id': reportId,
            'admin_id': adminUser.id,
            'decision': 'rejected',
            'notes': reason.trim(),
          });
          await client.from('audit_logs').insert({
            'actor_id': adminUser.id,
            'action': 'TOLAK LAPORAN',
            'target_id': reportId,
          });
        }
        debugPrint('[ReportService] adminRejectReport berhasil disinkronkan ke Supabase cloud.');
      } catch (e) {
        debugPrint('[ReportService] Supabase reject sync note: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Admin marks report as duplicate with reference to original report (Desain.md Section 6.3 & 15.11)
  Future<bool> adminMarkDuplicate(String reportId, {required String duplicateOfReportId, String? notes}) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Budi Santoso';
    final cleanRefId = duplicateOfReportId.replaceAll('#', '').trim();

    final updatedReport = report.copyWith(
      status: ReportStatus.duplicate,
      duplicateOf: cleanRefId,
      visibility: 'private',
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: ReportStatus.duplicate,
          actorName: '$adminName (Admin Operasional)',
          reason: 'Digabungkan ke tiket utama #$cleanRefId. ${notes ?? ''}'.trim(),
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;

    // Append to audit log
    _auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'aud-${_uuid.v4()}',
        timestamp: now,
        adminName: adminName,
        actionType: 'TANDAI DUPLIKAT',
        targetId: '#${report.id}',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Digabungkan ke tiket utama #$cleanRefId karena kesamaan lokasi temuan dan waktu berdekatan.',
        spatialDistanceMeters: 4.8,
      ),
    );

    // Sinkronisasi status duplikat ke cloud Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'status': 'duplicate',
        }).eq('id', reportId);

        if (_authService.isAuthenticated) {
          await client.from('report_reviews').insert({
            'report_id': reportId,
            'admin_id': adminUser.id,
            'decision': 'duplicate',
            'notes': notes ?? 'Duplikat tiket #$cleanRefId',
          });
          await client.from('audit_logs').insert({
            'actor_id': adminUser.id,
            'action': 'TANDAI DUPLIKAT',
            'target_id': reportId,
          });
        }
        debugPrint('[ReportService] adminMarkDuplicate berhasil disinkronkan ke Supabase cloud.');
      } catch (e) {
        debugPrint('[ReportService] Supabase duplicate sync note: $e');
      }
    }

    notifyListeners();
    return true;
  }

  // ================= CATEGORY MANAGEMENT =================
  void toggleCategoryStatus(String categoryId) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      final cur = _categories[idx];
      _categories[idx] = cur.copyWith(isActive: !cur.isActive);
      notifyListeners();
    }
  }

  // ================= USER MANAGEMENT =================
  void toggleUserSuspension(String userId) {
    final idx = _adminUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = _adminUsers[idx];
      _adminUsers[idx] = user.copyWith(
        isSuspended: !user.isSuspended,
        statusNote: !user.isSuspended ? 'Dinonaktifkan oleh Admin' : null,
      );
      notifyListeners();
    }
  }

  // ================= CLEANER TASKS =================

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

  // ================= CATEGORY MANAGEMENT (CRUD) =================

  /// Add a new environmental category
  void addCategory({
    required String name,
    required String code,
    required String description,
  }) {
    final newId = _uuid.v4();
    final now = DateTime.now();
    _categories.add(CategoryModel(
      id: newId,
      name: name.trim(),
      code: code.trim().isEmpty ? 'CW-CAT-0${_categories.length + 1}' : code.trim(),
      description: description.trim(),
      icon: Icons.category_outlined,
      reportCount: 0,
      updatedDate: '${now.day} Okt ${now.year}',
      isActive: true,
    ));
    notifyListeners();

    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        client.from('report_categories').insert({
          'id': newId,
          'name': name.trim(),
          'description': description.trim(),
          'is_active': true,
        }).then((_) {
          debugPrint('[ReportService] Kategori berhasil disimpan ke Supabase cloud: $name');
        }).catchError((e) {
          debugPrint('[ReportService] Supabase addCategory error: $e');
        });
      } catch (e) {
        debugPrint('[ReportService] Supabase addCategory error: $e');
      }
    }
  }

  /// Update an existing category
  void updateCategory(CategoryModel updated) {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      final now = DateTime.now();
      _categories[idx] = updated.copyWith(
        updatedDate: '${now.day} Okt ${now.year}',
      );
      notifyListeners();

      final client = SupabaseService().client;
      if (client != null && SupabaseService().isInitialized) {
        try {
          client.from('report_categories').update({
            'name': updated.name,
            'description': updated.description,
            'is_active': updated.isActive,
          }).eq('id', updated.id).catchError((e) {
            debugPrint('[ReportService] Supabase updateCategory error: $e');
          });
        } catch (e) {
          debugPrint('[ReportService] Supabase updateCategory error: $e');
        }
      }
    }
  }

  /// Toggle active/inactive status of a category
  void toggleCategoryActive(String id) {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final current = _categories[idx];
      final now = DateTime.now();
      final newStatus = !current.isActive;
      _categories[idx] = current.copyWith(
        isActive: newStatus,
        updatedDate: '${now.day} Okt ${now.year}',
      );
      notifyListeners();

      final client = SupabaseService().client;
      if (client != null && SupabaseService().isInitialized) {
        try {
          client.from('report_categories').update({
            'is_active': newStatus,
          }).eq('id', id).catchError((e) {
            debugPrint('[ReportService] Supabase toggleCategoryActive error: $e');
          });
        } catch (e) {
          debugPrint('[ReportService] Supabase toggleCategoryActive error: $e');
        }
      }
    }
  }

  /// Delete a category
  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();

    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        client.from('report_categories').delete().eq('id', id).catchError((e) {
          debugPrint('[ReportService] Supabase deleteCategory error: $e');
        });
      } catch (e) {
        debugPrint('[ReportService] Supabase deleteCategory error: $e');
      }
    }
  }
}
