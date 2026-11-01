import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'screens/admin_activity_log_screen.dart';
import 'screens/admin_categories_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_map_screen.dart';
import 'screens/admin_queue_screen.dart';
import 'screens/admin_review_detail_screen.dart';
import 'screens/admin_users_screen.dart';
import 'widgets/admin_responsive.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

class AdminShellScreen extends StatefulWidget {
  final String? initialReportId;
  final int initialTabIndex;

  const AdminShellScreen({
    super.key,
    this.initialReportId,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedTabIndex;
  String? _reviewingReportId;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _reviewingReportId = widget.initialReportId;
  }

  void _onSelectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
      _reviewingReportId = null; // Exit detail mode when switching tabs
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _openReportReview(String reportId) {
    setState(() {
      _selectedTabIndex = 1;
      _reviewingReportId = reportId;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _closeReportReview() {
    setState(() {
      _reviewingReportId = null;
    });
  }

  String get _breadcrumbTitle {
    if (_selectedTabIndex == 1 && _reviewingReportId != null) {
      return 'Tinjau Bukti #$_reviewingReportId';
    }
    switch (_selectedTabIndex) {
      case 0:
        return 'Ringkasan Operasional';
      case 1:
        return 'Antrean Verifikasi Laporan';
      case 2:
        return 'Peta Laporan GIS';
      case 3:
        return 'Manajemen Kategori Lingkungan';
      case 4:
        return 'Pengguna & Relawan Lapangan';
      case 5:
        return 'Riwayat Aktivitas & Audit Konsol';
      default:
        return 'Konsol Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminResponsive.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              backgroundColor: const Color(0xFF0F172A),
              child: AdminSidebar(
                selectedIndex: _selectedTabIndex,
                onSelectIndex: _onSelectTab,
                isDrawer: true,
                onLogout: () async {
                  await AuthService().signOut();
                },
              ),
            ),
      body: Row(
        children: [
          // Fixed Left Sidebar for Desktop / Web
          if (isDesktop)
            AdminSidebar(
              selectedIndex: _selectedTabIndex,
              onSelectIndex: _onSelectTab,
              onLogout: () async {
                await AuthService().signOut();
              },
            ),

          // Main View Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                AdminTopBar(
                  breadcrumbParent: 'Konsol',
                  breadcrumbChild: _breadcrumbTitle,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),

                // Content Views
                Expanded(
                  child: _buildCurrentContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    if (_selectedTabIndex == 1 && _reviewingReportId != null) {
      return AdminReviewDetailScreen(
        reportId: _reviewingReportId!,
        onBackToQueue: _closeReportReview,
      );
    }

    switch (_selectedTabIndex) {
      case 0:
        return AdminDashboardScreen(
          onNavigateToReview: _openReportReview,
          onNavigateToQueue: () => _onSelectTab(1),
          onNavigateToAuditLogs: () => _onSelectTab(5),
        );
      case 1:
        return AdminQueueScreen(
          onNavigateToReview: _openReportReview,
        );
      case 2:
        return AdminMapScreen(
          onNavigateToReview: _openReportReview,
        );
      case 3:
        return const AdminCategoriesScreen();
      case 4:
        return const AdminUsersScreen();
      case 5:
        return const AdminActivityLogScreen();
      default:
        return AdminDashboardScreen(
          onNavigateToReview: _openReportReview,
          onNavigateToQueue: () => _onSelectTab(1),
          onNavigateToAuditLogs: () => _onSelectTab(5),
        );
    }
  }
}
