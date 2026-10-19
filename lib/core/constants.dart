import 'package:flutter/material.dart';

class AppConstants {
  // Application Info
  static const String appName = 'CoastWatch';
  static const String appTagline = 'Aplikasi Pelaporan Lingkungan Pesisir Berbasis Geotagging';
  static const String appVersion = '1.0.0';

  // Storage / Bucket Names
  static const String bucketReportOriginals = 'report-originals';
  static const String bucketReportPublic = 'report-public';
  static const String bucketCleanupOriginals = 'cleanup-originals';

  // Validation Limits
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const double maxAccuracyThresholdMeters = 50.0; // Warnings if > 50m

  // Default Map Coordinates (Pesisir Kepulauan Riau / Pesisir Indonesia)
  static const double defaultLatitude = 1.1304;
  static const double defaultLongitude = 104.0530;
  static const double defaultZoom = 13.0;

  // OpenStreetMap Tile URL
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.coastwatch.app';
}

enum UserRole {
  guest,
  reporter,
  cleaner,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.guest:
        return 'guest';
      case UserRole.reporter:
        return 'reporter';
      case UserRole.cleaner:
        return 'cleaner';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.guest:
        return 'Pengunjung';
      case UserRole.reporter:
        return 'Pelapor';
      case UserRole.cleaner:
        return 'Relawan Pembersih';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'reporter':
        return UserRole.reporter;
      case 'cleaner':
        return UserRole.cleaner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.guest;
    }
  }
}

enum ReportStatus {
  pendingReview, // Menunggu Verifikasi
  verified,      // Terverifikasi
  inProgress,    // Sedang Ditangani
  cleaned,       // Selesai Dibersihkan
  rejected,      // Ditolak
  duplicate,     // Duplikat
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.pendingReview:
        return 'pending_review';
      case ReportStatus.verified:
        return 'verified';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.cleaned:
        return 'cleaned';
      case ReportStatus.rejected:
        return 'rejected';
      case ReportStatus.duplicate:
        return 'duplicate';
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.pendingReview:
        return 'Menunggu Verifikasi';
      case ReportStatus.verified:
        return 'Terverifikasi';
      case ReportStatus.inProgress:
        return 'Sedang Ditangani';
      case ReportStatus.cleaned:
        return 'Selesai Dibersihkan';
      case ReportStatus.rejected:
        return 'Ditolak';
      case ReportStatus.duplicate:
        return 'Duplikat';
    }
  }

  Color get textColor {
    switch (this) {
      case ReportStatus.pendingReview:
        return const Color(0xFFB45309); // Dark Amber
      case ReportStatus.verified:
        return const Color(0xFF2F4156); // CoastWatch Navy
      case ReportStatus.inProgress:
        return const Color(0xFF1D4ED8); // Blue
      case ReportStatus.cleaned:
        return const Color(0xFF15803D); // Green
      case ReportStatus.rejected:
        return const Color(0xFFB91C1C); // Red
      case ReportStatus.duplicate:
        return const Color(0xFF475569); // Slate
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReportStatus.pendingReview:
        return const Color(0xFFFEF3C7); // Soft Amber
      case ReportStatus.verified:
        return const Color(0xFFC8D9E6); // Sky Blue
      case ReportStatus.inProgress:
        return const Color(0xFFDBEAFE); // Soft Blue
      case ReportStatus.cleaned:
        return const Color(0xFFDCFCE7); // Soft Green
      case ReportStatus.rejected:
        return const Color(0xFFFEE2E2); // Soft Red
      case ReportStatus.duplicate:
        return const Color(0xFFF1F5F9); // Soft Slate
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pendingReview:
        return Icons.hourglass_top_rounded;
      case ReportStatus.verified:
        return Icons.verified_rounded;
      case ReportStatus.inProgress:
        return Icons.cleaning_services_rounded;
      case ReportStatus.cleaned:
        return Icons.task_alt_rounded;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
      case ReportStatus.duplicate:
        return Icons.content_copy_rounded;
    }
  }

  static ReportStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending_review':
        return ReportStatus.pendingReview;
      case 'verified':
        return ReportStatus.verified;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'cleaned':
        return ReportStatus.cleaned;
      case 'rejected':
        return ReportStatus.rejected;
      case 'duplicate':
        return ReportStatus.duplicate;
      default:
        return ReportStatus.pendingReview;
    }
  }
}
