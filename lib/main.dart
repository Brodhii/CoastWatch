import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI overlay (Navy status bar & clean navigation)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Indonesian date formatting
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('[Main] Date formatting init warning: $e');
  }

  // Initialize Supabase (with automatic fallback to Mock/Offline Demo mode if credentials not configured)
  await SupabaseService().initialize();

  // Initialize Auth state
  await AuthService().init();

  runApp(const CoastWatchApp());
}
