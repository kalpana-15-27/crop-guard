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

  // Backend API URL
  // Default to emulator localhost (10.0.2.2). On a physical Android device, change to host LAN IP (e.g., http://192.168.1.X:8000)
  static const String defaultBackendUrl = 'https://crop-guard-api.onrender.com';
  static String backendBaseUrl = defaultBackendUrl;

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
