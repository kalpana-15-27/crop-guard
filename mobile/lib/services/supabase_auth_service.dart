import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Supabase Authentication & Profile Service
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'en',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'preferred_language': preferredLanguage,
      },
    );
    return response;
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Send Password Reset Email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch User Profile details from `profiles` table
  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return res;
    } catch (_) {
      // If table isn't migrated yet, return profile metadata
      return {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Farmer',
        'preferred_language': user.userMetadata?['preferred_language'] ?? 'en',
      };
    }
  }

  /// Update Profile language or name
  Future<void> updateProfile({String? fullName, String? preferredLanguage}) async {
    final user = currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;

    try {
      await _client.from('profiles').update(updates).eq('id', user.id);
    } catch (_) {
      // Fallback update to auth user_metadata
      await _client.auth.updateUser(
        UserAttributes(data: updates),
      );
    }
  }
}
