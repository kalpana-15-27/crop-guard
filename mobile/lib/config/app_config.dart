import 'package:shared_preferences/shared_preferences.dart';

/// Global configuration constants for CropGuard AI Mobile Application
class AppConfig {
  static const String appName = 'CropGuard AI';
  static const String appTagline = 'Intelligent Pest Detection & Crop Protection';
  static const String appVersion = '1.0.0';

  // Supabase Configuration (Using User's Existing Project)
  static const String supabaseUrl = 'https://cxzayeoqbocryekkqiyk.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_ndB59weEGKDben6iY6odMg_hkNruZ3k';
  static const String supabaseAnonKey = supabasePublishableKey;
  static const String supabaseAuthCallbackUrl = 'com.cropguard.ai://reset-password';

  // Backend API URL (Default to live cloud on Render)
  static const String defaultBackendUrl = 'https://crop-guard-api.onrender.com';
  static String backendBaseUrl = defaultBackendUrl;

  static const String _prefKeyBackendUrl = 'saved_backend_url';

  /// Loads saved backend URL from phone storage on startup
  static Future<String> loadSavedBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyBackendUrl);
      if (saved != null && saved.trim().isNotEmpty) {
        backendBaseUrl = saved.trim();
      } else {
        backendBaseUrl = defaultBackendUrl;
      }
    } catch (_) {
      backendBaseUrl = defaultBackendUrl;
    }
    return backendBaseUrl;
  }

  /// Saves backend URL permanently to phone storage
  static Future<void> saveBackendUrl(String url) async {
    final clean = url.trim();
    backendBaseUrl = clean.isNotEmpty ? clean : defaultBackendUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBackendUrl, backendBaseUrl);
    } catch (_) {}
  }

  // Supported Crops
  static const List<String> supportedCrops = [
    'Paddy/Rice',
    'Cotton',
    'Tomato',
    'Chilli',
  ];

  // Model Version
  static const String modelVersion = 'yolo11s-v1.0';
}
