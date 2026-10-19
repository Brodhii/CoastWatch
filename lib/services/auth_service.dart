import 'package:flutter/foundation.dart';
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

  final SupabaseService _supabaseService = SupabaseService();

  Future<void> init() async {
    // Check if Supabase session exists
    final client = _supabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        _currentUser = UserProfileModel(
          id: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['display_name'] ?? 'Pengguna',
          role: UserRoleExtension.fromString(user.userMetadata?['role'] as String?),
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
        notifyListeners();
        return;
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final client = _supabaseService.client;
      if (client != null && _supabaseService.isInitialized) {
        final res = await client.auth.signInWithPassword(email: email, password: password);
        final user = res.user;
        if (user != null) {
          _currentUser = UserProfileModel(
            id: user.id,
            email: user.email ?? '',
            displayName: user.userMetadata?['display_name'] ?? 'Pengguna',
            role: UserRoleExtension.fromString(user.userMetadata?['role'] as String?),
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          );
          notifyListeners();
          return true;
        }
      }

      // Demo/Fallback Auth
      final mock = MockDataService.mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => UserProfileModel(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: email.trim(),
          displayName: email.split('@').first,
          role: email.contains('clean') || email.contains('relawan')
              ? UserRole.cleaner
              : UserRole.reporter,
          createdAt: DateTime.now(),
        ),
      );

      _currentUser = mock;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Login failed: $e');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // Role admin is prohibited on public registration (Desain.md Section 15.3)
      final safeRole = role == UserRole.admin ? UserRole.reporter : role;

      final client = _supabaseService.client;
      if (client != null && _supabaseService.isInitialized) {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'display_name': displayName,
            'role': safeRole.value,
          },
        );
        final user = res.user;
        if (user != null) {
          _currentUser = UserProfileModel(
            id: user.id,
            email: user.email ?? email,
            displayName: displayName,
            role: safeRole,
            createdAt: DateTime.now(),
          );
          notifyListeners();
          return true;
        }
      }

      // Demo fallback signup
      _currentUser = UserProfileModel(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        role: safeRole,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Sign up failed: $e');
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
