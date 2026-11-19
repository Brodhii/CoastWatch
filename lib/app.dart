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
            if (AuthService().currentRole == UserRole.cleaner) {
              return MaterialPageRoute(builder: (_) => const MainShellScreen());
            }
            return MaterialPageRoute(
              builder: (_) => const CreateReportCameraScreen(),
            );

          case AppRoutes.createReportForm:
            if (AuthService().currentRole == UserRole.cleaner) {
              return MaterialPageRoute(builder: (_) => const MainShellScreen());
            }
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CreateReportFormScreen(reportData: args),
            );

          case AppRoutes.createReportReview:
            if (AuthService().currentRole == UserRole.cleaner) {
              return MaterialPageRoute(builder: (_) => const MainShellScreen());
            }
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CreateReportReviewScreen(reportData: args),
            );

          case AppRoutes.createReportSuccess:
            if (AuthService().currentRole == UserRole.cleaner) {
              return MaterialPageRoute(builder: (_) => const MainShellScreen());
            }
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
  UserRole? _lastRole;

  void _onCleanerTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onReporterTabSelected(int index) {
    if (index == 2) {
      // Tap on "Buat Laporan"
      if (_authService.isGuest) {
        GuestPromptDialog.show(
          context,
          title: 'Kirim Laporan Pesisir',
          description: 'Masuk atau daftar terlebih dahulu untuk mengirimkan bukti foto ber-geotag ke sistem CoastWatch.',
        );
      } else {
        Navigator.pushNamed(context, AppRoutes.createReportCamera);
      }
      return;
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

        // Penyesuaian transisi indeks tab saat demo switch role
        if (_lastRole != null && _lastRole != _authService.currentRole) {
          final wasCleaner = _lastRole == UserRole.cleaner;
          final isCleanerNow = isCleaner;
          if (wasCleaner && !isCleanerNow) {
            // Relawan (4 tab: 0:Beranda, 1:Peta, 2:Tugas, 3:Profil) -> Pelapor/Pengunjung (5 tab: 0:Beranda, 1:Peta, 2:Lapor, 3:Laporan, 4:Profil)
            if (_currentIndex == 3) {
              _currentIndex = 4; // Tetap di Profil
            } else if (_currentIndex == 2) {
              _currentIndex = 3; // Tugas Saya -> Laporan Saya
            }
          } else if (!wasCleaner && isCleanerNow) {
            // Pelapor/Pengunjung -> Relawan
            if (_currentIndex == 4) {
              _currentIndex = 3; // Tetap di Profil
            } else if (_currentIndex == 3) {
              _currentIndex = 2; // Laporan Saya -> Tugas Saya
            } else if (_currentIndex == 2) {
              _currentIndex = 0; // Tombol Lapor -> Kembali ke Beranda Relawan
            }
          }
        }
        _lastRole = _authService.currentRole;

        // Tampilan antarmuka khusus Relawan: 4 Tab (Tanpa Tombol/Menu Lapor Sampah)
        if (isCleaner) {
          final List<Widget> cleanerPages = [
            CleanerDashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx.clamp(0, 3))),
            const PublicMapScreen(),
            const MyTasksScreen(),
            const ProfileScreen(),
          ];

          final safeCleanerIndex = _currentIndex.clamp(0, cleanerPages.length - 1);

          return Scaffold(
            body: IndexedStack(
              index: safeCleanerIndex,
              children: cleanerPages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: safeCleanerIndex,
              onTap: _onCleanerTabSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.navy,
              unselectedItemColor: AppTheme.textMuted,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Peta',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.cleaning_services_outlined),
                  activeIcon: Icon(Icons.cleaning_services),
                  label: 'Tugas Saya',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          );
        }

        // Tampilan Pelapor / Pengunjung: 5 Tab (Dengan Tombol Aksi Kamera Lapor di Tengah)
        final List<Widget> reporterPages = [
          HomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx.clamp(0, 4))),
          const PublicMapScreen(),
          const SizedBox.shrink(),
          const MyReportsScreen(),
          const ProfileScreen(),
        ];

        final safeReporterIndex = (_currentIndex == 2 ? 0 : _currentIndex).clamp(0, reporterPages.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeReporterIndex,
            children: reporterPages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex.clamp(0, 4),
            onTap: _onReporterTabSelected,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.navy,
            unselectedItemColor: AppTheme.textMuted,
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
              const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Laporan Saya',
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
