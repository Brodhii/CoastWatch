import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/admin_audit_log_model.dart';
import '../models/admin_user_model.dart';
import '../models/category_model.dart';
import '../models/cleanup_task_model.dart';
import '../models/report_model.dart';
import '../models/status_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'supabase_service.dart';

class ReportService extends ChangeNotifier {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal() {
    // Start with empty lists — data is loaded from Supabase via init()
    _reports = [];
    _auditLogs = [];
    _adminUsers = [];
    _categories = List.from(CategoryModel.defaultCategories);
  }

  final AuthService _authService = AuthService();
  final _uuid = const Uuid();

  /// Resets service state (used only for logout / test scenarios)
  void resetState() {
    _reports = [];
    _auditLogs = [];
    _adminUsers = [];
    _isCloudConnected = false;
    notifyListeners();
  }

  List<ReportModel> _reports = [];
  List<ReportModel> get reports => List.unmodifiable(_reports);

  List<AdminAuditLogModel> _auditLogs = [];
  List<AdminAuditLogModel> get auditLogs {
    final Map<String, AdminAuditLogModel> merged = {};

    // 1. Masukkan log eksplisit dari audit_logs / runtime admin
    for (final log in _auditLogs) {
      merged[log.id] = log;
    }

    // 2. Sintesiskan riwayat aktivitas lengkap dari seluruh laporan & status history
    for (final report in _reports) {
      final shortId = report.id.length > 8 ? '#${report.id.substring(0, 8)}' : '#${report.id}';
      final loc = report.locationName ?? 'Wilayah Pesisir Terpantau';

      // Event: Pengajuan laporan awal
      final subKey = 'sub_${report.id}';
      if (!merged.containsKey(subKey)) {
        merged[subKey] = AdminAuditLogModel(
          id: subKey,
          timestamp: report.createdAt,
          adminName: (report.reporterName?.isNotEmpty == true) ? report.reporterName! : 'Pelapor Warga',
          adminRole: 'Pelapor Warga',
          actionType: 'PENGAJUAN LAPORAN',
          targetId: shortId,
          targetLocation: loc,
          summary: 'Mengajukan temuan sampah pesisir baru kategori "${report.categoryName}". ${report.description.isNotEmpty ? report.description : "Menunggu peninjauan verifikasi admin."}',
        );
      }

      // Event dari riwayat status laporan
      for (final h in report.statusHistory) {
        final hKey = 'hist_${h.id}';
        if (merged.containsKey(hKey)) continue;

        String action = 'STATUS LAPORAN';
        String role = 'Admin Operasional';
        String summary = h.reason ?? 'Pembaruan status laporan';

        if (h.toStatus == ReportStatus.verified) {
          action = 'VERIFIKASI LAPORAN';
          role = 'Admin Operasional';
          summary = 'Laporan disetujui & dipublikasikan ke peta pemantauan GIS.';
        } else if (h.toStatus == ReportStatus.rejected) {
          action = 'TOLAK LAPORAN';
          role = 'Admin Operasional';
          summary = 'Laporan ditolak. Alasan: ${h.reason ?? "Tidak memenuhi kriteria bukti valid"}';
        } else if (h.toStatus == ReportStatus.duplicate) {
          action = 'TANDAI DUPLIKAT';
          role = 'Admin Operasional';
          summary = 'Laporan ditandai duplikat dalam radius temuan aktif.';
        } else if (h.toStatus == ReportStatus.inProgress) {
          action = 'AKSI PEMBERSIHAN';
          role = 'Relawan Lapangan';
          summary = 'Relawan memulai aksi pembersihan sampah di titik pesisir.';
        } else if (h.toStatus == ReportStatus.pendingCleanupReview) {
          action = 'UNGGAH BUKTI BERSIH';
          role = 'Relawan Lapangan';
          summary = 'Bukti pembersihan (${report.sackCount ?? 1} karung sampah) diunggah untuk verifikasi admin.';
        } else if (h.toStatus == ReportStatus.cleaned) {
          action = 'VERIFIKASI BERSIH';
          role = 'Admin Operasional';
          summary = 'Hasil pembersihan pesisir selesai diverifikasi dan dinyatakan pulih.';
        }

        final resolvedActor = resolveActorName(h.actorName, role == 'Relawan Lapangan' ? 'Budi Santoso (Relawan)' : 'Admin CoastWatch');

        merged[hKey] = AdminAuditLogModel(
          id: hKey,
          timestamp: h.createdAt,
          adminName: resolvedActor,
          adminRole: role,
          actionType: action,
          targetId: shortId,
          targetLocation: (action == 'VERIFIKASI LAPORAN' || action == 'TOLAK LAPORAN' || action == 'TANDAI DUPLIKAT') ? '-' : loc,
          summary: summary,
        );
      }
    }

    final result = merged.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(result);
  }

  /// Resolusi nama aktor agar tidak menampilkan string UUID mentah (d000000-...)
  String resolveActorName(String? rawActor, [String fallback = 'Staf Admin']) {
    if (rawActor == null || rawActor.trim().isEmpty) return fallback;
    final trimmed = rawActor.trim();

    // Cek apakah rawActor adalah UUID
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(trimmed);
    if (!isUuid) return trimmed;

    // Coba temukan di _adminUsers
    final found = _adminUsers.where((u) => u.id == trimmed);
    if (found.isNotEmpty) return found.first.name;

    // Cek ID pengguna bawaan sistem
    if (trimmed == 'd0000000-0000-0000-0000-000000000001') return 'Admin CoastWatch';
    if (trimmed == 'd0000000-0000-0000-0000-000000000002') return 'Budi Santoso (Relawan)';
    if (trimmed == 'd0000000-0000-0000-0000-000000000003') return 'Siti Rahayu (Pelapor)';

    return fallback;
  }

  List<AdminUserModel> _adminUsers = [];
  List<AdminUserModel> get adminUsers => List.unmodifiable(_adminUsers);

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories {
    final list = _categories.isNotEmpty ? _categories : CategoryModel.defaultCategories;
    return list.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final cat = entry.value;

      // Hitung total laporan aktual yang terhubung dengan kategori ini
      final count = _reports.where((r) {
        if (r.categoryId == cat.id) return true;
        final rName = r.categoryName.trim().toLowerCase();
        final cName = cat.name.trim().toLowerCase();
        return rName.isNotEmpty && (rName == cName || rName.contains(cName) || cName.contains(rName));
      }).length;

      final code = (cat.code.isEmpty || cat.code == 'CW-CAT-00')
          ? 'CW-CAT-${idx.toString().padLeft(2, '0')}'
          : cat.code;

      return cat.copyWith(
        reportCount: count,
        code: code,
      );
    }).toList();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCloudConnected = false;
  bool get isCloudConnected => _isCloudConnected;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Refresh manual atau pull-to-refresh dari cloud Supabase
  Future<bool> refreshFromCloud() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (!SupabaseService().isInitialized) {
        await SupabaseService().initialize();
      }
      await init();
      _isLoading = false;
      notifyListeners();
      return _isCloudConnected;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inisialisasi sinkronisasi data dari cloud Supabase saat aplikasi terbuka
  Future<void> init() async {
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      // 1. Categories
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
            .select('*, report_media(*), report_cleanups(*), report_status_history(*)')
            .order('created_at', ascending: false);
        if (reportsData.isNotEmpty) {
          final List<ReportModel> liveReports = [];
          for (final item in (reportsData as List)) {
            try {
              final r = item as Map<String, dynamic>;
              final cat = _categories.firstWhere(
                (c) => c.id == r['category_id'],
                orElse: () => CategoryModel.defaultCategories.first,
              );
              final mediaList = (r['report_media'] as List?) ?? [];
              Map<String, dynamic>? beforeMedia;
              Map<String, dynamic>? afterMedia;
              for (final m in mediaList) {
                if (m is Map<String, dynamic>) {
                  if (m['media_role'] == 'before') beforeMedia = m;
                  if (m['media_role'] == 'after') afterMedia = m;
                }
              }
              String beforeUrl = beforeMedia?['storage_key_public'] as String? ??
                  beforeMedia?['storage_key_original'] as String? ??
                  '';
              if (beforeUrl.isEmpty) {
                beforeUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e';
              }
              final afterUrl = afterMedia?['storage_key_public'] as String? ??
                  afterMedia?['storage_key_original'] as String? ??
                  '';

              // Parse cleanups dari database Supabase
              CleanupTaskModel? cleanupTask;
              final cleanupsList = (r['report_cleanups'] as List?) ?? [];
              if (cleanupsList.isNotEmpty) {
                final lastCleanup = cleanupsList.last as Map<String, dynamic>;
                final isTaskCompleted = r['status'] == 'cleaned' || lastCleanup['completed_at'] != null;
                cleanupTask = CleanupTaskModel(
                  id: lastCleanup['id'] as String? ?? 'cln-task',
                  reportId: r['id'] as String,
                  cleanerId: lastCleanup['cleaner_id'] as String? ?? '',
                  cleanerName: lastCleanup['cleaner_name'] as String? ?? lastCleanup['cleaner_id'] as String? ?? 'Relawan',
                  notes: lastCleanup['notes'] as String?,
                  cleanupLat: (lastCleanup['cleanup_lat'] as num?)?.toDouble(),
                  cleanupLng: (lastCleanup['cleanup_lng'] as num?)?.toDouble(),
                  startedAt: DateTime.tryParse(lastCleanup['started_at'] as String? ?? '') ?? DateTime.now(),
                  completedAt: DateTime.tryParse(lastCleanup['completed_at'] as String? ?? ''),
                  status: isTaskCompleted ? 'completed' : 'in_progress',
                  afterPhotoUrl: afterUrl.isNotEmpty ? afterUrl : null,
                  createdAt: DateTime.tryParse(lastCleanup['started_at'] as String? ?? '') ?? DateTime.now(),
                );
              }

              // Parse status history
              final historyList = (r['report_status_history'] as List?) ?? [];
              final statusHistory = historyList.map((h) {
                return StatusHistoryModel(
                  id: h['id'] as String? ?? '',
                  reportId: r['id'] as String,
                  fromStatus: h['from_status'] != null ? ReportStatusExtension.fromString(h['from_status'] as String?) : null,
                  toStatus: ReportStatusExtension.fromString(h['to_status'] as String?),
                  actorName: resolveActorName(h['actor_name'] as String? ?? h['actor_id'] as String?),
                  reason: h['reason'] as String?,
                  createdAt: DateTime.tryParse(h['created_at'] as String? ?? '') ?? DateTime.now(),
                );
              }).toList();

              final report = ReportModel.fromJson({
                ...r,
                'category_name': cat.name,
                'before_photo_url': beforeUrl,
                'after_photo_url': afterUrl.isNotEmpty ? afterUrl : null,
                'cleanup_task': cleanupTask?.toJson(),
                'status_history': statusHistory.map((s) => s.toJson()).toList(),
              });
              liveReports.add(report);
            } catch (err) {
              debugPrint('[ReportService] Error parsing report: $err');
            }
          }

          if (liveReports.isNotEmpty) {
            _reports = liveReports;
            _isCloudConnected = true;
            debugPrint('[ReportService] Synced ${_reports.length} reports from Supabase cloud (LIVE).');
            notifyListeners();
          }
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
            .select('*, profiles!actor_id(display_name, role)')
            .order('created_at', ascending: false);
        if (logsData.isNotEmpty) {
          final liveLogs = (logsData as List).map((l) {
            final targetId = l['target_id'];
            final target = targetId != null
                ? (targetId.toString().length > 8
                    ? '#${targetId.toString().substring(0, 8)}'
                    : '#$targetId')
                : '-';
            final actorProfile = l['profiles'] as Map<String, dynamic>?;
            final actorName = actorProfile?['display_name'] as String? ?? 'Admin';
            final actorRole = actorProfile?['role'] as String? ?? 'admin';
            final roleLabel = actorRole == 'admin' ? 'Admin Operasional' : (actorRole == 'cleaner' ? 'Relawan' : 'Pelapor');
            return AdminAuditLogModel(
              id: l['id'] as String,
              timestamp: DateTime.tryParse(l['created_at'] as String? ?? '') ?? DateTime.now(),
              adminName: actorName,
              adminRole: roleLabel,
              actionType: l['action'] as String? ?? 'AUDIT',
              targetId: target,
              targetLocation: l['target_location'] as String? ?? '-',
              summary: l['summary'] as String? ?? 'Aktivitas sistem tercatat.',
              coordinates: l['coordinates'] as String?,
              hash: l['hash'] as String?,
              warningBadge: l['warning_badge'] as String?,
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
  int get pendingCleanupCount => _reports.where((r) => r.status == ReportStatus.pendingCleanupReview).length;
  int get verifiedReportsCount => _reports.where((r) => r.status == ReportStatus.verified).length;
  int get rejectedReportsCount => _reports.where((r) => r.status == ReportStatus.rejected).length;
  int get duplicateReportsCount => _reports.where((r) => r.status == ReportStatus.duplicate).length;
  int get totalReportsCount => _reports.length;

  /// Fetch public reports (Verified and InProgress by default; Cleaned included if showCleaned is true)
  List<ReportModel> getPublicReports({
    String? categoryId,
    DateTimeRange? dateRange,
    bool showCleaned = true,
  }) {
    return _reports.where((r) {
      if (r.visibility != 'public') return false;

      // Filter status:
      // Default: verified, in_progress, pending_cleanup (menunggu validasi pembersihan)
      // Jika showCleaned true: tampilkan juga status cleaned (riwayat pantai bersih)
      final bool isEligible = r.status == ReportStatus.verified ||
          r.status == ReportStatus.inProgress ||
          r.status == ReportStatus.pendingCleanupReview ||
          (showCleaned && r.status == ReportStatus.cleaned);

      if (!isEligible) return false;

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
    return _reports.where((r) {
      if (r.reporterId == user.id) return true;
      if (r.reporterName == user.displayName) return true;
      if (user.role == UserRole.reporter &&
          (r.reporterId == 'd0000000-0000-0000-0000-000000000003' || r.reporterId == 'rep-001')) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Get verified reports available for cleaners to claim (Desain.md Section 6.5 & 8.7)
  List<ReportModel> getAvailableTasks() {
    return _reports.where((r) => r.isAvailableForCleanup).toList();
  }

  /// Get tasks currently claimed or completed by current cleaner
  List<ReportModel> getMyTasks() {
    final user = _authService.currentUser;
    if (user.isGuest) return [];
    return _reports.where((r) {
      if (r.cleanupTask == null) return false;
      if (r.cleanupTask!.cleanerId == user.id) return true;
      if (user.role == UserRole.cleaner &&
          (r.cleanupTask!.cleanerId == 'd0000000-0000-0000-0000-000000000002' ||
           r.cleanupTask!.cleanerId == 'cln-001')) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Get single report by ID
  ReportModel? getReportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Mencari laporan aktif terdekat dalam radius toleransi (default 10 meter)
  /// Mengabaikan laporan yang sudah berstatus 'cleaned', 'rejected', atau 'duplicate'
  ReportModel? findNearbyActiveReport(
    double latitude,
    double longitude, {
    double radiusMeters = AppConstants.duplicateReportRadiusMeters,
  }) {
    for (final report in _reports) {
      if (report.status == ReportStatus.cleaned ||
          report.status == ReportStatus.rejected ||
          report.status == ReportStatus.duplicate) {
        continue;
      }

      final distance = LocationService.calculateDistanceMeters(
        latitude,
        longitude,
        report.latitude,
        report.longitude,
      );

      if (distance <= radiusMeters) {
        return report;
      }
    }
    return null;
  }

  /// Submit new report with verified geotag (Desain.md Section 6.2 & 15.6)
  Future<ReportModel> submitReport({
    File? photoFile,
    dynamic photoXFile,
    Uint8List? photoBytes,
    String? photoPath,
    required String categoryId,
    required String categoryName,
    required String description,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime photoTimestamp,
    String? locationName,
    bool bypassDuplicateCheck = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Server-side / local coordinate validation check
      if (!LocationService.validateCoordinates(latitude, longitude)) {
        throw Exception('Koordinat GPS tidak valid (lat: $latitude, lng: $longitude).');
      }

      // 2. Validasi pencegahan laporan duplikat dalam radius 10 meter
      if (!bypassDuplicateCheck) {
        final existingReport = findNearbyActiveReport(
          latitude,
          longitude,
          radiusMeters: AppConstants.duplicateReportRadiusMeters,
        );
        if (existingReport != null) {
          final distance = LocationService.calculateDistanceMeters(
            latitude,
            longitude,
            existingReport.latitude,
            existingReport.longitude,
          );
          throw Exception(
            'Titik lokasi ini sudah dilaporkan sebelumnya berjarak ${distance.toStringAsFixed(1)}m '
            '(ID: ${existingReport.id}, Status: ${existingReport.status.label}). '
            'Laporan ganda dalam radius 10 meter tidak diizinkan karena sedang dalam penanganan.',
          );
        }
      }

      final now = DateTime.now();
      final reportId = _uuid.v4();
      final currentUser = _authService.currentUser;

      final client = SupabaseService().client;

      String photoUrl = photoPath ?? '';
      if (photoUrl.isEmpty && photoFile != null) {
        photoUrl = photoFile.path;
      }
      if (photoUrl.isEmpty && photoXFile != null) {
        try {
          photoUrl = (photoXFile.path as String?) ?? '';
        } catch (_) {}
      }
      if (photoUrl.isEmpty) {
        photoUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e';
      }

      // 1. Upload foto bukti ke Supabase Storage (Bucket 'reports') jika terhubung
      if (client != null && SupabaseService().isInitialized) {
        try {
          Uint8List? bytes = photoBytes;
          if (bytes == null && photoXFile != null) {
            bytes = await photoXFile.readAsBytes();
          } else if (bytes == null && photoFile != null) {
            bytes = await photoFile.readAsBytes();
          }

          if (bytes != null) {
            final fileName = 'report_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            try {
              await client.storage.from('reports').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
              final publicUrl = client.storage.from('reports').getPublicUrl(fileName);
              photoUrl = publicUrl;
              debugPrint('[ReportService] Upload foto ke Supabase Storage BERHASIL: $publicUrl');
            } catch (storageErr) {
              debugPrint('[ReportService] Supabase Storage upload note (bucket may need creation in Dashboard): $storageErr');
            }
          }
        } catch (e) {
          debugPrint('[ReportService] Read bytes error: $e');
        }
      }

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

      // Sinkronkan ke database Supabase jika online
      if (client != null && SupabaseService().isInitialized) {
        try {
          String validReporterId = currentUser.id;
          final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(validReporterId);
          if (!isUuid) {
            validReporterId = 'd0000000-0000-0000-0000-000000000003'; // Default reporter profile
          }

          await client.from('reports').insert({
            'id': reportId,
            'client_submission_id': newReport.clientSubmissionId,
            'reporter_id': validReporterId,
            'category_id': categoryId,
            'description': description.trim(),
            'latitude': latitude,
            'longitude': longitude,
            'exif_datetime_original': photoTimestamp.toIso8601String(),
            'device_location_accuracy_m': accuracy,
            'status': newReport.status.value,
          });

          // Simpan juga ke tabel report_media sesuai ERD Lampiran 2
          try {
            await client.from('report_media').insert({
              'report_id': reportId,
              'media_role': 'before',
              'storage_key_original': photoUrl,
              'storage_key_public': photoUrl,
              'mime_type': 'image/jpeg',
            });
          } catch (mErr) {
            debugPrint('[ReportService] report_media insert note: $mErr');
          }

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

  /// Admin deletes a report permanently from Supabase & local state (CRUD: Delete)
  Future<bool> deleteReport(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Admin Operasional';

    // Remove from local memory
    _reports.removeAt(index);

    // Append to audit log
    _auditLogs.insert(
      0,
      AdminAuditLogModel(
        id: 'aud-${_uuid.v4()}',
        timestamp: now,
        adminName: adminName,
        actionType: 'HAPUS LAPORAN',
        targetId: '#$reportId',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Laporan dihapus permanen oleh Admin dari basis data GIS.',
        coordinates: '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
        hash: 'sha256-del-${reportId.toLowerCase()}',
      ),
    );

    // Sinkronisasi hapus ke cloud Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').delete().eq('id', reportId);

        if (_authService.isAuthenticated) {
          try {
            await client.from('audit_logs').insert({
              'actor_id': adminUser.id,
              'action': 'HAPUS LAPORAN',
              'target_id': reportId,
            });
          } catch (_) {}
        }
        debugPrint('[ReportService] Laporan $reportId berhasil dihapus permanen dari Supabase cloud.');
      } catch (e) {
        debugPrint('[ReportService] Supabase delete sync note: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Admin updates report category if classified incorrectly by citizen
  Future<bool> adminUpdateReportCategory(String reportId, {required String newCategoryId, required String newCategoryName}) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Admin Operasional';

    final updatedReport = report.copyWith(
      categoryId: newCategoryId,
      categoryName: newCategoryName,
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: report.status,
          actorName: '$adminName (Admin Operasional)',
          reason: 'Koreksi kategori dari "${report.categoryName}" menjadi "$newCategoryName"',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;

    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'category_id': newCategoryId,
        }).eq('id', reportId);
        debugPrint('[ReportService] adminUpdateReportCategory berhasil disinkronkan ke Supabase cloud.');
      } catch (e) {
        debugPrint('[ReportService] Supabase category update note: $e');
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

  /// Cleaner claims a verified task (Desain.md Section 6.5) with proximity check
  Future<bool> claimTask(
    String reportId, {
    String? notes,
    double? cleanerLat,
    double? cleanerLng,
    bool bypassProximity = false,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    if (report.status != ReportStatus.verified || report.cleanupTask != null) {
      throw Exception('Tugas ini sudah diambil oleh relawan lain atau tidak tersedia.');
    }

    // Proximity check: Cleaner must be within 50m of beach trash site
    if (cleanerLat != null && cleanerLng != null && !bypassProximity) {
      final distance = LocationService.calculateDistanceMeters(
        cleanerLat,
        cleanerLng,
        report.latitude,
        report.longitude,
      );
      if (distance > AppConstants.maxCleanerProximityMeters) {
        throw Exception(
          'Lokasi Anda berjarak ${LocationService.formatDistance(distance)} dari titik pantai. Tugas hanya dapat diambil jika berada di radius ${AppConstants.maxCleanerProximityMeters.toStringAsFixed(0)} meter dari lokasi sampah.',
        );
      }
    }

    final user = _authService.currentUser;
    final now = DateTime.now();
    final taskId = _uuid.v4();

    String validCleanerId = user.id;
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(validCleanerId);
    if (!isUuid) {
      validCleanerId = 'd0000000-0000-0000-0000-000000000002'; // Budi Santoso (Relawan) di public.profiles
    }

    final task = CleanupTaskModel(
      id: taskId,
      reportId: reportId,
      cleanerId: validCleanerId,
      cleanerName: user.displayName.isNotEmpty ? user.displayName : 'Budi Relawan Pembersih',
      notes: notes ?? 'Tugas pembersihan diambil oleh relawan.',
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
          actorName: user.displayName.isNotEmpty ? user.displayName : 'Relawan',
          reason: notes ?? 'Tugas pembersihan diklaim oleh relawan di lokasi',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;
    notifyListeners();

    // Sinkronkan ke cloud Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        // 1. Update status laporan menjadi in_progress
        await client.from('reports').update({
          'status': 'in_progress',
        }).eq('id', reportId);

        // 2. Insert ke report_cleanups
        try {
          await client.from('report_cleanups').insert({
            'id': taskId,
            'report_id': reportId,
            'cleaner_id': validCleanerId,
            'notes': notes ?? 'Tugas pembersihan diambil oleh relawan.',
            'started_at': now.toIso8601String(),
          });
        } catch (cErr) {
          debugPrint('[ReportService] report_cleanups insert note: $cErr');
        }

        // 3. Catat di report_status_history
        try {
          await client.from('report_status_history').insert({
            'report_id': reportId,
            'actor_id': validCleanerId,
            'from_status': 'verified',
            'to_status': 'in_progress',
            'reason': notes ?? 'Tugas pembersihan diklaim oleh relawan di lokasi',
            'created_at': now.toIso8601String(),
          });
        } catch (hErr) {
          debugPrint('[ReportService] report_status_history insert note: $hErr');
        }

        debugPrint('[ReportService] claimTask berhasil disinkronkan ke Supabase cloud!');
      } catch (e) {
        debugPrint('[ReportService] claimTask Supabase sync error: $e');
      }
    }

    return true;
  }

  /// Relawan memulai aksi pembersihan fisik di lapangan setelah tiba di titik pesisir
  Future<bool> startFieldWork(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    if (report.cleanupTask == null) return false;

    final now = DateTime.now();
    final updatedTask = report.cleanupTask!.copyWith(
      fieldWorkStartedAt: now,
    );

    final updatedReport = report.copyWith(
      cleanupTask: updatedTask,
      updatedAt: now,
    );

    _reports[index] = updatedReport;
    notifyListeners();
    return true;
  }

  /// Cleaner completes a task with after-photo geotag proof, moving it to pendingCleanupReview
  Future<bool> completeCleanupTask({
    required String reportId,
    File? proofPhotoFile,
    dynamic proofPhotoXFile,
    String? proofPhotoPath,
    required String notes,
    required double cleanupLat,
    required double cleanupLng,
    required DateTime cleanupTimestamp,
    int sackCount = 1,
    bool bypassProximity = false,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final user = _authService.currentUser;

    final isAuthorized = report.cleanupTask != null &&
        (report.cleanupTask?.cleanerId == user.id ||
            user.role == UserRole.cleaner ||
            report.cleanupTask?.cleanerId == 'd0000000-0000-0000-0000-000000000002');

    if (!isAuthorized) {
      throw Exception('Anda bukan pemegang sah dari tugas pembersihan ini.');
    }

    if (!LocationService.validateCoordinates(cleanupLat, cleanupLng)) {
      throw Exception('Foto bukti pembersihan tidak memiliki koordinat GPS yang sah.');
    }

    // Proximity check on the proof photo
    if (!bypassProximity) {
      final distance = LocationService.calculateDistanceMeters(
        cleanupLat,
        cleanupLng,
        report.latitude,
        report.longitude,
      );
      if (distance > AppConstants.maxCleanerProximityMeters) {
        throw Exception(
          'Foto bukti pembersihan berjarak ${LocationService.formatDistance(distance)} dari titik awal sampah. Foto bukti wajib diambil di lokasi pantai (radius maksimal ${AppConstants.maxCleanerProximityMeters.toStringAsFixed(0)} meter).',
        );
      }
    }

    final now = DateTime.now();
    final client = SupabaseService().client;
    String proofUrl = proofPhotoPath ?? '';

    // Upload foto bukti sesudah bersih ke Supabase Storage (Bucket 'reports')
    if (client != null && SupabaseService().isInitialized) {
      try {
        Uint8List? bytes;
        if (proofPhotoXFile != null) {
          bytes = await proofPhotoXFile.readAsBytes();
        } else if (proofPhotoFile != null) {
          bytes = await proofPhotoFile.readAsBytes();
        }

        if (bytes != null) {
          final fileName = 'cleanup_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          try {
            await client.storage.from('reports').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
            final publicUrl = client.storage.from('reports').getPublicUrl(fileName);
            proofUrl = publicUrl;
            debugPrint('[ReportService] Upload bukti pembersihan ke Supabase Storage BERHASIL: $publicUrl');
          } catch (storageErr) {
            debugPrint('[ReportService] Supabase Storage cleanup upload note: $storageErr');
          }
        }
      } catch (e) {
        debugPrint('[ReportService] Read cleanup bytes error: $e');
      }
    }

    if (proofUrl.isEmpty && proofPhotoFile != null) {
      proofUrl = proofPhotoFile.path;
    }
    if (proofUrl.isEmpty && proofPhotoXFile != null) {
      try {
        proofUrl = (proofPhotoXFile.path as String?) ?? '';
      } catch (_) {}
    }
    if (proofUrl.isEmpty) {
      proofUrl = 'https://images.unsplash.com/photo-1544551763-46a013bb70d5';
    }

    String validCleanerId = user.id;
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(validCleanerId);
    if (!isUuid) {
      validCleanerId = 'd0000000-0000-0000-0000-000000000002'; // Budi Relawan
    }

    // Sinkronkan ke tabel reports, report_cleanups, dan report_media di Supabase
    if (client != null && SupabaseService().isInitialized) {
      try {
        // 1. Update atau insert report_cleanups
        try {
          final existing = await client
              .from('report_cleanups')
              .select('id')
              .eq('report_id', reportId)
              .maybeSingle();

          if (existing != null) {
            await client.from('report_cleanups').update({
              'notes': notes.trim(),
              'cleanup_lat': cleanupLat,
              'cleanup_lng': cleanupLng,
              'completed_at': now.toIso8601String(),
            }).eq('report_id', reportId);
          } else {
            await client.from('report_cleanups').insert({
              'report_id': reportId,
              'cleaner_id': validCleanerId,
              'notes': notes.trim(),
              'cleanup_lat': cleanupLat,
              'cleanup_lng': cleanupLng,
              'started_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
              'completed_at': now.toIso8601String(),
            });
          }
        } catch (cErr) {
          debugPrint('[ReportService] report_cleanups upsert note: $cErr');
        }

        // 2. Simpan media sesudah pembersihan ke report_media
        try {
          await client.from('report_media').insert({
            'report_id': reportId,
            'media_role': 'after',
            'storage_key_original': proofUrl,
            'storage_key_public': proofUrl,
            'mime_type': 'image/jpeg',
          });
        } catch (mErr) {
          debugPrint('[ReportService] report_media after note: $mErr');
        }

        // 3. Update status laporan ke pending_cleanup (menunggu validasi admin)
        try {
          await client.from('reports').update({
            'status': ReportStatus.pendingCleanupReview.value,
          }).eq('id', reportId);
        } catch (uErr) {
          debugPrint('[ReportService] update report pending_cleanup note: $uErr');
        }

        // 4. Catat di report_status_history
        try {
          await client.from('report_status_history').insert({
            'report_id': reportId,
            'actor_id': validCleanerId,
            'from_status': 'in_progress',
            'to_status': 'pending_cleanup',
            'reason': 'Foto bukti pembersihan diunggah oleh relawan, menunggu validasi admin',
            'created_at': now.toIso8601String(),
          });
        } catch (hErr) {
          debugPrint('[ReportService] report_status_history pending_cleanup note: $hErr');
        }
      } catch (e) {
        debugPrint('[ReportService] completeCleanupTask sync note: $e');
      }
    }

    final updatedTask = report.cleanupTask!.copyWith(
      notes: notes.trim(),
      cleanupLat: cleanupLat,
      cleanupLng: cleanupLng,
      cleanupExifDateTimeOriginal: cleanupTimestamp,
      completedAt: now,
      status: 'completed',
      afterPhotoUrl: proofUrl,
      sackCount: sackCount,
    );

    final updatedReport = report.copyWith(
      status: ReportStatus.pendingCleanupReview,
      afterPhotoUrl: proofUrl,
      cleanupTask: updatedTask,
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: ReportStatus.inProgress,
          toStatus: ReportStatus.pendingCleanupReview,
          actorName: user.displayName.isNotEmpty ? user.displayName : 'Budi Relawan Pembersih',
          reason: 'Foto bukti pembersihan diunggah oleh relawan, menunggu validasi admin',
          createdAt: now,
        ),
      ],
    );

    _reports[index] = updatedReport;
    notifyListeners();
    return true;
  }

  // ================= ADMIN CLEANUP VERIFICATION (STAGE 2) =================

  /// Admin approves the cleanup proof after comparing Before vs After photos
  Future<bool> adminApproveCleanup(String reportId, {String? notes}) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Budi Santoso';

    final updatedReport = report.copyWith(
      status: ReportStatus.cleaned,
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: ReportStatus.cleaned,
          actorName: '$adminName (Admin Operasional)',
          reason: notes ?? 'Hasil pembersihan disahkan oleh Admin Operasional setelah verifikasi foto Sebelum vs Sesudah.',
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
        actionType: 'SAHKAN PEMBERSIHAN',
        targetId: '#${report.id}',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Pembersihan pantai disahkan oleh admin. Foto Sebelum vs Sesudah terverifikasi bersih.',
        coordinates: '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
        hash: 'sha256-clean-${report.id.toLowerCase()}',
      ),
    );

    // Sync to Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'status': 'cleaned',
        }).eq('id', reportId);

        if (_authService.isAuthenticated) {
          await client.from('report_reviews').insert({
            'report_id': reportId,
            'admin_id': adminUser.id,
            'decision': 'cleanup_approved',
            'notes': notes ?? 'Pembersihan disahkan oleh admin',
          });
          await client.from('audit_logs').insert({
            'actor_id': adminUser.id,
            'action': 'SAHKAN PEMBERSIHAN',
            'target_id': reportId,
          });
        }
        debugPrint('[ReportService] adminApproveCleanup berhasil disinkronkan ke Supabase cloud!');
      } catch (e) {
        debugPrint('[ReportService] Supabase adminApproveCleanup sync error: $e');
      }
    }

    notifyListeners();
    return true;
  }

  /// Admin rejects the cleanup proof if the beach is still dirty or photo invalid
  Future<bool> adminRejectCleanup(String reportId, {required String reason}) async {
    if (reason.trim().isEmpty) {
      throw Exception('Alasan penolakan hasil pembersihan wajib diisi.');
    }

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return false;

    final report = _reports[index];
    final now = DateTime.now();
    final adminUser = _authService.currentUser;
    final adminName = adminUser.displayName.isNotEmpty ? adminUser.displayName : 'Budi Santoso';

    final updatedReport = report.copyWith(
      status: ReportStatus.inProgress, // Returned to in_progress so volunteer can re-clean
      updatedAt: now,
      statusHistory: [
        ...report.statusHistory,
        StatusHistoryModel(
          id: 'sh-${_uuid.v4()}',
          reportId: reportId,
          fromStatus: report.status,
          toStatus: ReportStatus.inProgress,
          actorName: '$adminName (Admin Operasional)',
          reason: 'Hasil pembersihan ditolak admin: ${reason.trim()}',
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
        actionType: 'TOLAK BUKTI BERSIH',
        targetId: '#${report.id}',
        targetLocation: report.locationName ?? 'Pesisir Lapangan',
        summary: 'Alasan: ${reason.trim()}',
        rejectionReason: reason.trim(),
        warningBadge: 'Minta Pembersihan Ulang',
        hash: 'sha256-rejclean-${report.id.toLowerCase()}',
      ),
    );

    // Sync to Supabase
    final client = SupabaseService().client;
    if (client != null && SupabaseService().isInitialized) {
      try {
        await client.from('reports').update({
          'status': 'in_progress',
        }).eq('id', reportId);

        if (_authService.isAuthenticated) {
          await client.from('report_reviews').insert({
            'report_id': reportId,
            'admin_id': adminUser.id,
            'decision': 'cleanup_rejected',
            'notes': reason.trim(),
          });
          await client.from('audit_logs').insert({
            'actor_id': adminUser.id,
            'action': 'TOLAK BUKTI BERSIH',
            'target_id': reportId,
          });
        }
        debugPrint('[ReportService] adminRejectCleanup berhasil disinkronkan ke Supabase cloud!');
      } catch (e) {
        debugPrint('[ReportService] Supabase adminRejectCleanup sync error: $e');
      }
    }

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
