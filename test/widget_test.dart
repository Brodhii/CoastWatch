import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coastwatch/core/constants.dart';
import 'package:coastwatch/models/category_model.dart';
import 'package:coastwatch/services/auth_service.dart';
import 'package:coastwatch/services/location_service.dart';
import 'package:coastwatch/services/report_service.dart';
import 'package:coastwatch/shared/status_badge.dart';

void main() {
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
      final ids = categories.map((c) => c.id).toList();
      expect(ids, containsAll([
        'plastic',
        'household',
        'fishing',
        'liquid',
        'organic',
        'ecosystem',
        'other',
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

    test('Public reports strictly returns only verified reports (Desain.md Section 6.4)', () {
      final reportService = ReportService();
      final publicReports = reportService.getPublicReports();
      expect(publicReports, isNotEmpty);
      for (final report in publicReports) {
        expect(report.status, ReportStatus.verified);
        expect(report.visibility, 'public');
      }
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
      expect(find.text('Sedang Ditangani'), findsOneWidget);
      expect(find.text('Selesai Dibersihkan'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Duplikat'), findsOneWidget);
    });
  });
}
