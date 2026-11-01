import 'package:flutter/foundation.dart';

/// Multilingual Localization Provider supporting English and Telugu (తెలుగు)
class AppStrings with ChangeNotifier {
  static final AppStrings _instance = AppStrings._internal();
  factory AppStrings() => _instance;
  AppStrings._internal();

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  bool get isTelugu => _currentLanguage == 'te';

  void setLanguage(String langCode) {
    if (langCode == 'en' || langCode == 'te') {
      _currentLanguage = langCode;
      notifyListeners();
    }
  }

  // String dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General & Brand
      'appName': 'CropGuard AI',
      'tagline': 'Intelligent Pest Detection & Crop Protection',
      'experimentalDisclaimer': 'CropGuard AI is an AI-assisted detection tool. Always cross-check with agricultural officers before applying major chemical interventions.',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'retry': 'Retry',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',

      // Navigation
      'navHome': 'Home',
      'navScan': 'Scan Pest',
      'navHistory': 'History',
      'navProfile': 'Profile',

      // Auth
      'loginTitle': 'Welcome Back',
      'loginSubtitle': 'Log in to protect your crops with AI',
      'email': 'Email Address',
      'emailHint': 'farmer@example.com',
      'password': 'Password',
      'passwordHint': 'Enter your password',
      'confirmPassword': 'Confirm Password',
      'confirmPasswordHint': 'Re-enter your password',
      'fullName': 'Full Name',
      'fullNameHint': 'Enter your full name',
      'loginButton': 'Sign In',
      'registerButton': 'Create Account',
      'dontHaveAccount': 'Don\'t have an account?',
      'alreadyHaveAccount': 'Already have an account?',
      'signUp': 'Sign Up',
      'signIn': 'Sign In',
      'forgotPassword': 'Forgot Password?',
      'passwordsDoNotMatch': 'Passwords do not match',
      'invalidEmail': 'Please enter a valid email address',
      'passwordTooShort': 'Password must be at least 6 characters',
      'resetPasswordTitle': 'Reset Password',
      'resetPasswordSubtitle': 'Enter and confirm your new password below',
      'newPassword': 'New Password',
      'newPasswordHint': 'Enter your new password',
      'saveNewPassword': 'Save New Password',
      'passwordResetSuccess': 'Password updated successfully! Please sign in with your new password.',
      'invalidRecoveryLink': 'Password recovery link has expired or is invalid.',

      // Dashboard
      'greetingMorning': 'Good Morning',
      'greetingAfternoon': 'Good Afternoon',
      'greetingEvening': 'Good Evening',
      'farmer': 'Farmer',
      'quickScan': 'Scan Pest Now',
      'quickScanSubtitle': 'Take a photo or upload an image to detect harmful crop pests',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'supportedCrops': 'Supported Crops',
      'cropPaddy': 'Paddy / Rice',
      'cropCotton': 'Cotton',
      'cropTomato': 'Tomato',
      'cropChilli': 'Chilli',
      'recentActivity': 'Recent Scans',
      'viewAll': 'View All',
      'noScansYet': 'No scans recorded yet. Tap "Scan Pest" to start your first detection!',
      'statsTotalScans': 'Total Scans',
      'statsPestsDetected': 'Pests Found',
      'statsHealthyScans': 'Clear / Clean',
      'dailyTipTitle': 'Farmer Advisory Tip',
      'dailyTipBody': 'Regular monitoring of the underside of leaves helps identify aphids and thrips before large colony outbreaks.',

      // Scan Screen
      'scanTitle': 'Pest Detection',
      'selectCrop': 'Select Crop Type',
      'capturePrompt': 'Align the insect or infected leaf clearly in good natural light.',
      'retake': 'Retake',
      'remove': 'Remove',
      'analyzeButton': 'Detect Pest Now',
      'analyzing': 'Analyzing image with YOLO11s AI...',
      'detecting': 'Processing pest features...',
      'uploading': 'Uploading image securely...',

      // Results Screen
      'resultTitle': 'Detection Results',
      'noPestDetected': 'No Pest Detected',
      'noPestMessage': 'No harmful crop pests were detected in this image with sufficient confidence. If you notice crop damage, inspect closely under leaves or take another photo with better lighting.',
      'confidence': 'Confidence Score',
      'pestCount': 'Pest Count',
      'affectedCrops': 'Target Crops',
      'damageSymptoms': 'Damage Symptoms',
      'preventiveGuidance': 'Preventive Guidance & Next Steps',
      'annotatedImage': 'Annotated Detection View',
      'originalImage': 'Original Photo',
      'saveToHistory': 'Saved to Scan History',
      'scanAnother': 'Scan Another Image',

      // History Screen
      'historyTitle': 'Detection History',
      'deleteConfirmTitle': 'Delete Scan Record?',
      'deleteConfirmBody': 'Are you sure you want to permanently delete this scan record?',
      'statusDetected': 'Pest Detected',
      'statusClean': 'No Pest Found',

      // Profile Screen
      'profileTitle': 'Farmer Profile',
      'preferredLanguage': 'Language / భాష',
      'english': 'English',
      'telugu': 'తెలుగు (Telugu)',
      'appInfo': 'About CropGuard AI',
      'appInfoDescription': 'CropGuard AI is an academic B.Tech CSE research project built to assist Indian farmers with instant deep-learning pest identification and sustainable crop protection.',
      'logout': 'Sign Out',
      'logoutConfirm': 'Are you sure you want to log out?',
    },

    'te': {
      // General & Brand
      'appName': 'క్రాప్‌గార్డ్ AI (CropGuard AI)',
      'tagline': 'స్మార్ట్ పురుగుల గుర్తింపు మరియు పైరు సంరక్షణ',
      'experimentalDisclaimer': 'క్రాప్‌గార్డ్ AI అనేది రైతుల సహాయం కోసం రూపొందించబడిన ఆర్టిఫిషియల్ ఇంటెలిజెన్స్ సాధనం. రసాయన మందులు వాడే ముందు వ్యవసాయ అధికారులను సంప్రదించండి.',
      'save': 'భద్రపరచు',
      'cancel': 'రద్దు చేయి',
      'delete': 'తొలగించు',
      'confirm': 'ధృవీకరించు',
      'retry': 'మళ్ళీ ప్రయత్నించు',
      'loading': 'వేచి ఉండండి...',
      'error': 'లోపం',
      'success': 'విజయం',

      // Navigation
      'navHome': 'హోమ్',
      'navScan': 'పురుగు స్కానింగ్',
      'navHistory': 'చరిత్ర',
      'navProfile': 'ప్రొఫైల్',

      // Auth
      'loginTitle': 'స్వాగతం',
      'loginSubtitle': 'మీ పంటలను రక్షించుకోవడానికి లాగిన్ అవ్వండి',
      'email': 'ఈమెయిల్ చిరునామా',
      'emailHint': 'farmer@example.com',
      'password': 'పాస్‌వర్డ్',
      'passwordHint': 'మీ పాస్‌వర్డ్‌ను నమోదు చేయండి',
      'confirmPassword': 'పాస్‌వర్డ్ నిర్ధారించండి',
      'confirmPasswordHint': 'పాస్‌వర్డ్‌ను మళ్ళీ నమోదు చేయండి',
      'fullName': 'పూర్తి పేరు',
      'fullNameHint': 'మీ పేరు రాయండి',
      'loginButton': 'లాగిన్ చేయండి',
      'registerButton': 'ఖాతా సృష్టించండి',
      'dontHaveAccount': 'ఖాతా లేదా?',
      'alreadyHaveAccount': 'ఇప్పటికే ఖాతా ఉందా?',
      'signUp': 'రిజిస్టర్ అవ్వండి',
      'signIn': 'సైన్ ఇన్',
      'forgotPassword': 'పాస్‌వర్డ్ మర్చిపోయారా?',
      'passwordsDoNotMatch': 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు',
      'invalidEmail': 'సరైన ఈమెయిల్ నమోదు చేయండి',
      'passwordTooShort': 'పాస్‌వర్డ్ కనీసం 6 అక్షరాలు ఉండాలి',
      'resetPasswordTitle': 'పాస్‌వర్డ్ రీసెట్ చేయండి',
      'resetPasswordSubtitle': 'మీ కొత్త పాస్‌వర్డ్‌ను క్రింద నమోదు చేసి నిర్ధారించండి',
      'newPassword': 'కొత్త పాస్‌వర్డ్',
      'newPasswordHint': 'మీ కొత్త పాస్‌వర్డ్ రాయండి',
      'saveNewPassword': 'కొత్త పాస్‌వర్డ్‌ను సేవ్ చేయండి',
      'passwordResetSuccess': 'పాస్‌వర్డ్ విజయవంతంగా నవీకరించబడింది! దయచేసి కొత్త పాస్‌వర్డ్‌తో లాగిన్ చేయండి.',
      'invalidRecoveryLink': 'పాస్‌వర్డ్ రికవరీ లింక్ గడువు ముగిసింది లేదా చెల్లదు.',

      // Dashboard
      'greetingMorning': 'శుభోదయం',
      'greetingAfternoon': 'శుభ మధ్యాహ్నం',
      'greetingEvening': 'శుభ సాయంత్రం',
      'farmer': 'రైతు సోదరా',
      'quickScan': 'పురుగును గుర్తించండి',
      'quickScanSubtitle': 'పంటకు నష్టం కలిగించే పురుగులను ఫోటో తీసి వెంటనే తెలుసుకోండి',
      'camera': 'కెమెరా',
      'gallery': 'గ్యాలరీ',
      'supportedCrops': 'మద్దతు ఉన్న పంటలు',
      'cropPaddy': 'వరి (Paddy)',
      'cropCotton': 'పత్తి (Cotton)',
      'cropTomato': 'టమోటా (Tomato)',
      'cropChilli': 'మిరప (Chilli)',
      'recentActivity': 'ఇటీవలి స్కానింగ్‌లు',
      'viewAll': 'అన్నీ చూడండి',
      'noScansYet': 'ఇంకా ఎలాంటి స్కానింగ్‌లు లేవు. మొదటిసారి పురుగును గుర్తించడానికి "పురుగు స్కానింగ్" నొక్కండి!',
      'statsTotalScans': 'మొత్తం స్కానింగ్‌లు',
      'statsPestsDetected': 'గుర్తించిన పురుగులు',
      'statsHealthyScans': 'స్వచ్ఛమైన పైరు',
      'dailyTipTitle': 'రైతులకు సలహా',
      'dailyTipBody': 'ఆకుల అడుగు భాగాన్ని క్రమం తప్పకుండా గమనించడం వల్ల పేనుబంక, తామర పురుగులను ముందస్తుగానే నివారించవచ్చు.',

      // Scan Screen
      'scanTitle': 'పురుగుల గుర్తింపు',
      'selectCrop': 'పంట రకాన్ని ఎంచుకోండి',
      'capturePrompt': 'పురుగు లేదా సోకిన ఆకు స్పష్టంగా కనిపించేలా సహజ కాంతిలో ఫోటో తీయండి.',
      'retake': 'మళ్ళీ తీయండి',
      'remove': 'తొలగించు',
      'analyzeButton': 'పురుగును గుర్తించండి',
      'analyzing': 'AI ద్వారా ఫోటోను విశ్లేషిస్తున్నాము...',
      'detecting': 'పురుగు లక్షణాలను పరిశీలిస్తున్నాము...',
      'uploading': 'చిత్రాన్ని అప్‌లోడ్ చేస్తున్నాము...',

      // Results Screen
      'resultTitle': 'గుర్తింపు ఫలితాలు',
      'noPestDetected': 'పురుగు ఏదీ కనుగొనబడలేదు',
      'noPestMessage': 'ఈ చిత్రంలో ఎలాంటి హానికరమైన పురుగులు గుర్తించబడలేదు. పంట నష్టం కనిపిస్తే, ఆకుల అడుగున స్పష్టంగా కనిపించేలా మరో ఫోటో తీయండి.',
      'confidence': 'ఖచ్చితత్వ శాతం',
      'pestCount': 'పురుగుల సంఖ్య',
      'affectedCrops': 'ప్రభావిత పంటలు',
      'damageSymptoms': 'నష్టం కలిగించే లక్షణాలు',
      'preventiveGuidance': 'నివారణ చర్యలు & సలహాలు',
      'annotatedImage': 'గుర్తించిన ప్రదేశం (బాక్స్)',
      'originalImage': 'అసలు ఫోటో',
      'saveToHistory': 'చరిత్రలో భద్రపరచబడింది',
      'scanAnother': 'మరో ఫోటో స్కాన్ చేయండి',

      // History Screen
      'historyTitle': 'స్కానింగ్ చరిత్ర',
      'deleteConfirmTitle': 'రికార్డును తొలగించాలా?',
      'deleteConfirmBody': 'ఈ స్కానింగ్ రికార్డును శాశ్వతంగా తొలగించాలనుకుంటున్నారా?',
      'statusDetected': 'పురుగు గుర్తించబడింది',
      'statusClean': 'పురుగు లేదు',

      // Profile Screen
      'profileTitle': 'రైతు ప్రొఫైల్',
      'preferredLanguage': 'భాష / Language',
      'english': 'English',
      'telugu': 'తెలుగు (Telugu)',
      'appInfo': 'క్రాప్‌గార్డ్ AI గురించి',
      'appInfoDescription': 'క్రాప్‌గార్డ్ AI అనేది భారతీయ రైతులకు సహాయపడటానికి డీప్ లెర్నింగ్ ద్వారా రూపొందించబడిన B.Tech CSE పరిశోధన ప్రాజెక్ట్.',
      'logout': 'లాగ్ అవుట్',
      'logoutConfirm': 'మీరు ఖచ్చితంగా లాగ్ అవుట్ అవ్వాలనుకుంటున్నారా?',
    }
  };

  String tr(String key) {
    return _localizedValues[_currentLanguage]?[key] ??
           _localizedValues['en']?[key] ??
           key;
  }
}
