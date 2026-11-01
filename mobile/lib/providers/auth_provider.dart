import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

/// State Management Provider for Supabase Authentication
class AuthProvider with ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecoveryActive = false;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecoveryActive => _isRecoveryActive;

  void setRecoveryActive(bool val) {
    _isRecoveryActive = val;
    notifyListeners();
  }

  String get displayName =>
      _profile?['full_name'] ??
      _user?.userMetadata?['full_name'] ??
      _user?.email?.split('@').first ??
      'Farmer';

  String get userEmail => _user?.email ?? '';

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    _user = _authService.currentUser;
    if (_user != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    _profile = await _authService.fetchProfile();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.signIn(email: email.trim(), password: password);
      _user = res.user;
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'en',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        preferredLanguage: preferredLanguage,
      );
      _user = res.user;
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    _isRecoveryActive = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
