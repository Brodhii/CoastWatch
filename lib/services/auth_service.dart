import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_profile_model.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Initial state is Guest as per Desain.md Section 15.2
  UserProfileModel _currentUser = UserProfileModel.guest();
  UserProfileModel get currentUser => _currentUser;

  bool get isGuest => _currentUser.isGuest;
  bool get isAuthenticated => !_currentUser.isGuest;
  UserRole get currentRole => _currentUser.role;

  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;

  final SupabaseService _supabaseService = SupabaseService();

  Future<void> init() async {
    // Check if Supabase session exists
    final client = _supabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        String displayName = user.userMetadata?['display_name'] ?? user.email?.split('@').first ?? 'Pengguna';
        UserRole role = UserRoleExtension.fromString(user.userMetadata?['role'] as String?);

        try {
          final prof = await client.from('profiles').select().eq('id', user.id).maybeSingle();
          if (prof != null) {
            displayName = prof['display_name'] as String? ?? displayName;
            role = UserRoleExtension.fromString(prof['role'] as String?);
          }
        } catch (e) {
          debugPrint('[AuthService] Init profile fetch error: $e');
        }

        _currentUser = UserProfileModel(
          id: user.id,
          email: user.email ?? '',
          displayName: displayName,
          role: role,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
        notifyListeners();
        return;
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _lastAuthError = null;
    final trimmedInput = email.trim();
    if (trimmedInput.isEmpty || password.isEmpty) {
      _lastAuthError = 'Username/email dan kata sandi tidak boleh kosong.';
      return false;
    }

    // Mendukung login menggunakan username pendek (admin, relawan, pelapor) maupun email lengkap
    final lower = trimmedInput.toLowerCase();
    final List<String> candidateEmails = [];

    if (lower.contains('@')) {
      candidateEmails.add(lower);
      if (lower.endsWith('@coastwatch.id')) {
        candidateEmails.add(lower.replaceFirst('@coastwatch.id', '@gmail.com'));
      } else if (lower.endsWith('@gmail.com')) {
        candidateEmails.add(lower.replaceFirst('@gmail.com', '@coastwatch.id'));
      }
    } else {
      if (lower == 'admin') {
        candidateEmails.addAll(['admin@coastwatch.id', 'admin@gmail.com']);
      } else if (lower == 'pelapor' || lower == 'reporter') {
        candidateEmails.addAll(['pelapor@gmail.com', 'pelapor@coastwatch.id']);
      } else if (lower == 'relawan' || lower == 'cleaner') {
        candidateEmails.addAll(['relawan@gmail.com', 'relawan@coastwatch.id']);
      } else {
        candidateEmails.addAll(['$lower@gmail.com', '$lower@coastwatch.id']);
      }
    }

    final client = _supabaseService.client;
    if (client == null || !_supabaseService.isInitialized) {
      _lastAuthError = 'Koneksi ke backend Supabase belum siap. Periksa koneksi internet Anda.';
      return false;
    }

    // 1. Coba autentikasi ke Supabase Cloud
    for (final candidateEmail in candidateEmails) {
      try {
        final res = await client.auth.signInWithPassword(
          email: candidateEmail,
          password: password,
        );
        final user = res.user;
        if (user != null) {
          String displayName = user.userMetadata?['display_name'] ?? candidateEmail.split('@').first;
          UserRole role = UserRoleExtension.fromString(user.userMetadata?['role'] as String?);

          // Cek profil dari tabel public.profiles untuk memastikan role akurat (admin/cleaner/reporter)
          try {
            final prof = await client.from('profiles').select().eq('id', user.id).maybeSingle();
            if (prof != null) {
              displayName = prof['display_name'] as String? ?? displayName;
              role = UserRoleExtension.fromString(prof['role'] as String?);
            }
          } catch (e) {
            debugPrint('[AuthService] Profile fetch note: $e');
          }

          _currentUser = UserProfileModel(
            id: user.id,
            email: user.email ?? candidateEmail,
            displayName: displayName,
            role: role,
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          );
          _lastAuthError = null;
          debugPrint('[AuthService] Login via Supabase cloud BERHASIL: ${_currentUser.displayName} (${_currentUser.role.value})');
          notifyListeners();
          return true;
        }
      } on AuthException catch (e) {
        debugPrint('[AuthService] Supabase AuthException for $candidateEmail: ${e.message} (code: ${e.statusCode})');
        final msg = e.message.toLowerCase();
        if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
          _lastAuthError = 'Email belum dikonfirmasi di server Supabase.';
        } else {
          _lastAuthError = 'Username/email atau kata sandi salah. Harap periksa kembali.';
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase login error: $e');
      }
    }

    // 2. Fallback Demo Mode: Jika menggunakan password standar 'password'
    if (password == 'password') {
      UserProfileModel? fallbackUser;
      if (lower == 'admin' || lower == 'admin@coastwatch.id') {
        fallbackUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.admin);
      } else if (lower == 'relawan' || lower == 'cleaner' || lower == 'relawan@coastwatch.id' || lower == 'relawan@gmail.com') {
        fallbackUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.cleaner);
      } else if (lower == 'pelapor' || lower == 'reporter' || lower == 'pelapor@coastwatch.id' || lower == 'pelapor@gmail.com') {
        fallbackUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.reporter);
      }

      if (fallbackUser != null) {
        UserProfileModel activeUser = fallbackUser;
        try {
          final prof = await client.from('profiles').select().eq('id', activeUser.id).maybeSingle();
          if (prof != null) {
            activeUser = UserProfileModel(
              id: activeUser.id,
              email: activeUser.email,
              displayName: prof['display_name'] as String? ?? activeUser.displayName,
              role: UserRoleExtension.fromString(prof['role'] as String?),
              createdAt: activeUser.createdAt,
            );
          }
        } catch (_) {}

        _currentUser = activeUser;
        _lastAuthError = null;
        debugPrint('[AuthService] Login fallback ke akun role BERHASIL: ${_currentUser.displayName} (${_currentUser.role.value})');
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    _lastAuthError = null;
    try {
      // Role admin is prohibited on public registration (Desain.md Section 15.3)
      final safeRole = role == UserRole.admin ? UserRole.reporter : role;

      final client = _supabaseService.client;
      if (client == null || !_supabaseService.isInitialized) {
        _lastAuthError = 'Koneksi ke backend Supabase belum siap. Periksa koneksi internet Anda.';
        return false;
      }

      String effectiveEmail = email.trim();
      if (!effectiveEmail.contains('@')) {
        effectiveEmail = '$effectiveEmail@gmail.com';
      }

      final res = await client.auth.signUp(
        email: effectiveEmail,
        password: password,
        data: {
          'display_name': displayName.trim(),
          'role': safeRole.value,
        },
      );
      final user = res.user;
      if (user != null) {
        // Upsert ke public.profiles untuk memastikan sinkronisasi data profil & role
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'display_name': displayName.trim(),
            'role': safeRole.value,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('[AuthService] Profile upsert note: $e');
        }

        // Langsung autentikasi pengguna ke sesi aktif
        _currentUser = UserProfileModel(
          id: user.id,
          email: user.email ?? effectiveEmail,
          displayName: displayName.trim(),
          role: safeRole,
          createdAt: DateTime.now(),
        );
        notifyListeners();
        return true;
      } else {
        _lastAuthError = 'Gagal mendaftarkan akun. Silakan coba beberapa saat lagi.';
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('[AuthService] Supabase signUp AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('user already exists')) {
        _lastAuthError = 'Email atau username ini sudah terdaftar. Silakan langsung masuk di halaman Login.';
      } else if (msg.contains('rate limit')) {
        _lastAuthError = 'Batas permintaan Supabase terlampaui. Silakan gunakan akun bawaan atau coba lagi nanti.';
      } else {
        _lastAuthError = e.message;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Sign up failed: $e');
      _lastAuthError = 'Pendaftaran gagal: $e';
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final client = _supabaseService.client;
      if (client != null && _supabaseService.isInitialized) {
        await client.auth.signOut();
      }
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
    } finally {
      _currentUser = UserProfileModel.guest();
      notifyListeners();
    }
  }

  /// Switch role for demo/examination purposes
  void switchRoleForDemo(UserRole targetRole) {
    switch (targetRole) {
      case UserRole.guest:
        _currentUser = UserProfileModel.guest();
        break;
      case UserRole.reporter:
        _currentUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.reporter);
        break;
      case UserRole.cleaner:
        _currentUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.cleaner);
        break;
      case UserRole.admin:
        _currentUser = MockDataService.mockUsers.firstWhere((u) => u.role == UserRole.admin);
        break;
    }
    notifyListeners();
  }
}
