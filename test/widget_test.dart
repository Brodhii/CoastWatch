import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:coastwatch/app.dart';
import 'package:coastwatch/core/constants.dart';
import 'package:coastwatch/models/category_model.dart';
import 'package:coastwatch/services/auth_service.dart';
import 'package:coastwatch/services/location_service.dart';
import 'package:coastwatch/services/report_service.dart';
import 'package:coastwatch/shared/status_badge.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('CoastWatch Core & Business Logic Tests', () {
    test('Default user state must be Guest (Desain.md Section 15.2)', () {
      final authService = AuthService();
      expect(authService.isGuest, isTrue);
      expect(authService.currentRole, UserRole.guest);
      expect(authService.currentUser.displayName, 'Pengunjung');
    });

    test('All 7 required coastal categories are present (Desain.md Section 10.1)', () {
      final categories = CategoryModel.defaultCategories;
      expect(categories.length, 7);
      final codes = categories.map((c) => c.code).toList();
      expect(codes, containsAll([
        'CW-CAT-01',
        'CW-CAT-02',
        'CW-CAT-03',
        'CW-CAT-04',
        'CW-CAT-05',
        'CW-CAT-06',
        'CW-CAT-07',
      ]));
    });

    test('Location validation correctly checks coordinate bounds', () {
      // Valid coordinates (Pesisir Indonesia)
      expect(LocationService.validateCoordinates(1.1304, 104.0530), isTrue);
      // Null island (0, 0) is flagged as suspicious
      expect(LocationService.validateCoordinates(0.0, 0.0), isFalse);
      // Out of bounds
      expect(LocationService.validateCoordinates(95.0, 104.0), isFalse);
      expect(LocationService.validateCoordinates(1.0, 200.0), isFalse);
    });

    test('Public reports returns verified and in-progress, but hides cleaned by default', () {
      final reportService = ReportService();
      final publicReports = reportService.getPublicReports(showCleaned: false);
      expect(publicReports, isNotEmpty);
      for (final report in publicReports) {
        expect(report.status, anyOf(ReportStatus.verified, ReportStatus.inProgress));
        expect(report.status, isNot(ReportStatus.cleaned));
        expect(report.visibility, 'public');
      }

      // When showCleaned is enabled, cleaned reports are included
      final allWithCleaned = reportService.getPublicReports(showCleaned: true);
      final hasCleaned = allWithCleaned.any((r) => r.status == ReportStatus.cleaned);
      expect(hasCleaned, isTrue);
    });

    test('Claiming a task moves it from available tasks to in-progress', () async {
      final reportService = ReportService();
      final availableBefore = reportService.getAvailableTasks();
      expect(availableBefore, isNotEmpty);

      final targetReport = availableBefore.first;
      final success = await reportService.claimTask(targetReport.id);
      expect(success, isTrue);

      final availableAfter = reportService.getAvailableTasks();
      expect(availableAfter.any((r) => r.id == targetReport.id), isFalse);

      final updated = reportService.getReportById(targetReport.id);
      expect(updated?.status, ReportStatus.inProgress);
      expect(updated?.cleanupTask, isNotNull);
    });

    test('Two-stage verification flow: claim -> submit proof (pendingCleanupReview) -> adminApproveCleanup (cleaned)', () async {
      final reportService = ReportService();
      reportService.resetToMockData();
      final available = reportService.getAvailableTasks();
      expect(available, isNotEmpty);

      final report = available.first;
      // 1. Volunteer claims task
      final claimed = await reportService.claimTask(report.id, bypassProximity: true);
      expect(claimed, isTrue);
      expect(reportService.getReportById(report.id)?.status, ReportStatus.inProgress);

      // 2. Volunteer submits cleanup proof (stage 2 review)
      final submitted = await reportService.completeCleanupTask(
        reportId: report.id,
        proofPhotoPath: 'https://example.com/cleaned.jpg',
        notes: 'Sampah pantai telah dibersihkan',
        cleanupLat: report.latitude,
        cleanupLng: report.longitude,
        cleanupTimestamp: DateTime.now(),
        bypassProximity: true,
      );
      expect(submitted, isTrue);
      expect(reportService.getReportById(report.id)?.status, ReportStatus.pendingCleanupReview);

      // 3. Admin inspects and approves cleanup
      final approved = await reportService.adminApproveCleanup(report.id, notes: 'Pembersihan disahkan');
      expect(approved, isTrue);
      expect(reportService.getReportById(report.id)?.status, ReportStatus.cleaned);
    });

    test('Proximity distance check enforces 50m max threshold', () {
      // Titik sama (0 meter) -> lolos
      expect(LocationService.isWithinProximity(1.1304, 104.0530, 1.1304, 104.0530), isTrue);

      // Titik sangat jauh (~11 km) -> tolak
      expect(LocationService.isWithinProximity(1.1304, 104.0530, 1.2304, 104.0530), isFalse);
    });

    test('Duplicate report prevention prevents submitting within 10 meters of an active report', () async {
      final reportService = ReportService();
      reportService.resetToMockData();

      // Ambil laporan aktif yang sudah ada
      final existingReport = reportService.reports.firstWhere((r) => r.status != ReportStatus.cleaned);

      // Cek titik yang persis sama (0 meter) terdeteksi sebagai duplikat
      final detected = reportService.findNearbyActiveReport(
        existingReport.latitude,
        existingReport.longitude,
      );
      expect(detected, isNotNull);
      expect(detected!.id, existingReport.id);

      // Submit pada titik yang sama tanpa bypass harus ditolak dengan Exception
      expect(
        () async => await reportService.submitReport(
          categoryId: 'plastic',
          categoryName: 'Sampah Plastik',
          description: 'Laporan duplikat kedua',
          latitude: existingReport.latitude,
          longitude: existingReport.longitude,
          accuracy: 5.0,
          photoTimestamp: DateTime.now(),
          bypassDuplicateCheck: false,
        ),
        throwsA(isA<Exception>()),
      );

      // Jika menggunakan bypassDuplicateCheck: true, laporan berhasil disubmit
      final submitted = await reportService.submitReport(
        categoryId: 'plastic',
        categoryName: 'Sampah Plastik',
        description: 'Laporan dengan bypass',
        latitude: existingReport.latitude,
        longitude: existingReport.longitude,
        accuracy: 5.0,
        photoTimestamp: DateTime.now(),
        bypassDuplicateCheck: true,
      );
      expect(submitted.id, isNotEmpty);
    });

    testWidgets('StatusBadge displays correct Indonesian text and icon for all statuses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: ReportStatus.pendingReview),
                StatusBadge(status: ReportStatus.verified),
                StatusBadge(status: ReportStatus.inProgress),
                StatusBadge(status: ReportStatus.pendingCleanupReview),
                StatusBadge(status: ReportStatus.cleaned),
                StatusBadge(status: ReportStatus.rejected),
                StatusBadge(status: ReportStatus.duplicate),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Sedang Dibersihkan'), findsOneWidget);
      expect(find.text('Menunggu Validasi Pembersihan'), findsOneWidget);
      expect(find.text('Selesai Dibersihkan'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Duplikat'), findsOneWidget);
    });

    test('Volunteer phased operational flow: claim -> startFieldWork (active timer) -> complete with sackCount', () async {
      final reportService = ReportService();
      reportService.resetToMockData();
      final available = reportService.getAvailableTasks();
      expect(available, isNotEmpty);

      final report = available.first;
      // 1. Claim task
      await reportService.claimTask(report.id, bypassProximity: true);
      var current = reportService.getReportById(report.id)!;
      expect(current.status, ReportStatus.inProgress);
      expect(current.isFieldWorkActive, isFalse);

      // 2. Start field work (Tahap 2)
      await reportService.startFieldWork(report.id);
      current = reportService.getReportById(report.id)!;
      expect(current.isFieldWorkActive, isTrue);
      expect(current.cleanupTask?.fieldWorkStartedAt, isNotNull);

      // 3. Complete cleanup with sack tally (Tahap 3)
      await reportService.completeCleanupTask(
        reportId: report.id,
        proofPhotoPath: 'https://example.com/clean.jpg',
        notes: 'Pesisir bersih dari sampah',
        cleanupLat: report.latitude,
        cleanupLng: report.longitude,
        cleanupTimestamp: DateTime.now(),
        sackCount: 4,
        bypassProximity: true,
      );

      current = reportService.getReportById(report.id)!;
      expect(current.status, ReportStatus.pendingCleanupReview);
      expect(current.sackCount, 4);
      expect(current.cleanupTask?.status, 'completed');
    });

    test('Task locking prevents double claiming of in-progress tasks', () async {
      final reportService = ReportService();
      reportService.resetToMockData();
      final available = reportService.getAvailableTasks();
      final report = available.first;

      // First volunteer claims
      final firstClaim = await reportService.claimTask(report.id, bypassProximity: true);
      expect(firstClaim, isTrue);

      // Second attempt to claim must throw Exception
      expect(
        () async => await reportService.claimTask(report.id, bypassProximity: true),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('MainShellScreen role separation: Relawan (Cleaner) must NOT have Lapor tab', (tester) async {
      final authService = AuthService();
      authService.switchRoleForDemo(UserRole.cleaner);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Cleaner shell must have 4 navigation items in BottomNavigationBar: Beranda, Peta, Tugas Saya, Profil
      final navBar = find.byType(BottomNavigationBar);
      expect(find.descendant(of: navBar, matching: find.text('Beranda')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Peta')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Tugas Saya')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Profil')), findsOneWidget);

      // Must NOT have 'Lapor' tab or photo icon
      expect(find.descendant(of: navBar, matching: find.text('Lapor')), findsNothing);
      expect(find.descendant(of: navBar, matching: find.byIcon(Icons.add_a_photo_outlined)), findsNothing);
    });

    testWidgets('MainShellScreen role separation: Pelapor (Reporter) has Lapor action button', (tester) async {
      final authService = AuthService();
      authService.switchRoleForDemo(UserRole.reporter);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Reporter shell has 5 navigation items including Lapor in BottomNavigationBar
      final navBar = find.byType(BottomNavigationBar);
      expect(find.descendant(of: navBar, matching: find.text('Beranda')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Peta')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Lapor')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Laporan Saya')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Profil')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.byIcon(Icons.add_a_photo_outlined)), findsOneWidget);
    });
  });
}
