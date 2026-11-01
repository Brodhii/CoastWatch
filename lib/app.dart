import 'package:flutter/material.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'models/report_model.dart';
import 'profile/profile_screen.dart';
import 'public/home_screen.dart';
import 'public/public_map_screen.dart';
import 'public/public_report_detail_screen.dart';
import 'roles/admin/admin_shell_screen.dart';
import 'roles/cleaner/screens/cleaner_dashboard_screen.dart';
import 'roles/cleaner/screens/cleaner_task_detail_screen.dart';
import 'roles/cleaner/screens/cleanup_proof_screen.dart';
import 'roles/cleaner/screens/cleanup_success_screen.dart';
import 'roles/cleaner/screens/my_tasks_screen.dart';
import 'roles/reporter/screens/create_report_camera_screen.dart';
import 'roles/reporter/screens/create_report_form_screen.dart';
import 'roles/reporter/screens/create_report_review_screen.dart';
import 'roles/reporter/screens/create_report_success_screen.dart';
import 'roles/reporter/screens/my_reports_screen.dart';
import 'roles/reporter/screens/reporter_report_detail_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'services/auth_service.dart';
import 'shared/guest_prompt_dialog.dart';

class CoastWatchApp extends StatelessWidget {
  const CoastWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.initial:
            return MaterialPageRoute(builder: (_) => const MainShellScreen());

          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case AppRoutes.register:
            return MaterialPageRoute(builder: (_) => const RegisterScreen());

          case AppRoutes.publicReportDetail:
            final reportId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => PublicReportDetailScreen(reportId: reportId),
            );

          case AppRoutes.createReportCamera:
            return MaterialPageRoute(
              builder: (_) => const CreateReportCameraScreen(),
            );

          case AppRoutes.createReportForm:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CreateReportFormScreen(reportData: args),
            );

          case AppRoutes.createReportReview:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CreateReportReviewScreen(reportData: args),
            );

          case AppRoutes.createReportSuccess:
            final report = settings.arguments as ReportModel;
            return MaterialPageRoute(
              builder: (_) => CreateReportSuccessScreen(report: report),
            );

          case AppRoutes.myReportDetail:
            final reportId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ReporterReportDetailScreen(reportId: reportId),
            );

          case AppRoutes.cleanerTaskDetail:
            final reportId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => CleanerTaskDetailScreen(reportId: reportId),
            );

          case AppRoutes.cleanupProof:
            final reportId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => CleanupProofScreen(reportId: reportId),
            );

          case AppRoutes.cleanupSuccess:
            final report = settings.arguments as ReportModel?;
            return MaterialPageRoute(
              builder: (_) => CleanupSuccessScreen(report: report),
            );

          case AppRoutes.adminShell:
            return MaterialPageRoute(builder: (_) => const AdminShellScreen());

          case AppRoutes.adminReviewDetail:
            final reportId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => AdminShellScreen(initialReportId: reportId, initialTabIndex: 1),
            );

          default:
            return MaterialPageRoute(builder: (_) => const MainShellScreen());
        }
      },
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      // Tap on "Buat Laporan"
      if (_authService.isGuest) {
        GuestPromptDialog.show(
          context,
          title: 'Kirim Laporan Pesisir',
          description: 'Masuk atau daftar terlebih dahulu untuk mengirimkan bukti foto ber-geotag ke sistem CoastWatch.',
        );
        return;
      } else if (_authService.currentRole == UserRole.cleaner) {
        // Show guidance or open camera
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Peran Relawan Pembersih', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            content: const Text(
              'Sebagai relawan, tugas utama Anda adalah mengambil aksi bersih dari menu "Tugas". Apakah Anda ingin tetap membuat laporan pesisir baru?',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.createReportCamera);
                },
                child: const Text('Lanjut Buat Laporan'),
              ),
            ],
          ),
        );
        return;
      } else {
        Navigator.pushNamed(context, AppRoutes.createReportCamera);
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        // If current role is Admin, directly render the Admin Console
        if (_authService.currentRole == UserRole.admin) {
          return const AdminShellScreen();
        }

        final isCleaner = _authService.currentRole == UserRole.cleaner;

        final List<Widget> pages = [
          // 0: Home / Beranda
          isCleaner
              ? CleanerDashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx))
              : HomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),

          // 1: Peta Publik
          const PublicMapScreen(),

          // 2: Placeholder for Create Action (handled in _onTabSelected)
          const SizedBox.shrink(),

          // 3: Laporan Saya / Tugas Saya
          isCleaner ? const MyTasksScreen() : const MyReportsScreen(),

          // 4: Profil
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex == 2 ? 0 : _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Peta',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.white, size: 20),
                ),
                label: 'Lapor',
              ),
              BottomNavigationBarItem(
                icon: Icon(isCleaner ? Icons.cleaning_services_outlined : Icons.assignment_outlined),
                activeIcon: Icon(isCleaner ? Icons.cleaning_services : Icons.assignment),
                label: isCleaner ? 'Tugas' : 'Laporan Saya',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
