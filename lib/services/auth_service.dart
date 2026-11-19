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
    final String effectiveEmail;
    if (lower.contains('@')) {
      effectiveEmail = lower;
    } else if (lower == 'cleaner') {
      effectiveEmail = 'relawan@coastwatch.id';
    } else if (lower == 'reporter') {
      effectiveEmail = 'pelapor@coastwatch.id';
    } else {
      effectiveEmail = '$lower@coastwatch.id';
    }

    final client = _supabaseService.client;
    if (client == null || !_supabaseService.isInitialized) {
      _lastAuthError = 'Koneksi ke backend Supabase belum siap. Periksa koneksi internet Anda.';
      return false;
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: effectiveEmail,
        password: password,
      );
      final user = res.user;
      if (user != null) {
        String displayName = user.userMetadata?['display_name'] ?? effectiveEmail.split('@').first;
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
          email: user.email ?? effectiveEmail,
          displayName: displayName,
          role: role,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
        _lastAuthError = null;
        debugPrint('[AuthService] Login via Supabase cloud BERHASIL: ${_currentUser.displayName} (${_currentUser.role.value})');
        notifyListeners();
        return true;
      } else {
        _lastAuthError = 'Autentikasi gagal: Sesi pengguna tidak ditemukan.';
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('[AuthService] Supabase AuthException: ${e.message} (code: ${e.statusCode})');
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        _lastAuthError = 'Username/email atau kata sandi salah. Harap periksa kembali.';
      } else if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
        _lastAuthError = 'Email belum dikonfirmasi di server Supabase.';
      } else {
        _lastAuthError = e.message;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Supabase login error: $e');
      _lastAuthError = 'Gagal terhubung ke server autentikasi: $e';
      return false;
    }
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

      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName.trim(),
          'role': safeRole.value,
        },
      );
      final user = res.user;
      if (user != null) {
        if (res.session != null) {
          _currentUser = UserProfileModel(
            id: user.id,
            email: user.email ?? email,
            displayName: displayName.trim(),
            role: safeRole,
            createdAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      } else {
        _lastAuthError = 'Gagal mendaftarkan akun. Silakan coba beberapa saat lagi.';
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('[AuthService] Supabase signUp AuthException: ${e.message}');
      _lastAuthError = e.message;
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
