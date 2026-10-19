class AppConfig {
  // Supabase Configuration
  // Note: Ganti dengan kredensial Supabase Free milik Anda jika tersedia.
  // Aplikasi CoastWatch secara cerdas berjalan dalam mode Mock/Offline Fallback
  // jika kredensial belum disetel atau koneksi gagal, sehingga siap didemokan!
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder-coastwatch.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
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
