class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mxyptgfagmatwkzlnzqp.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_OKSFYmACAAGVJADdfmUyEg_Xny-NI7S',
  );

  static bool get isSupabaseConfigured {
    return !supabaseUrl.contains('placeholder') && !supabaseAnonKey.contains('placeholder');
  }

  // Study Area Limits (Pesisir Batam / Kepulauan Riau)
  static const double minLat = 0.8;
  static const double maxLat = 1.6;
  static const double minLng = 103.7;
  static const double maxLng = 104.6;

  static bool isWithinCoastalStudyArea(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }
}
