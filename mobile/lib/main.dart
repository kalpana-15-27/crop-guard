import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/theme.dart';
import 'localization/app_strings.dart';
import 'providers/auth_provider.dart';
import 'providers/detection_provider.dart';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'services/detection_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load permanently saved backend URL from phone storage (defaults to Render cloud)
  await AppConfig.loadSavedBackendUrl();
  DetectionService().updateBaseUrl(AppConfig.backendBaseUrl);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.cardWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase with existing project credentials
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStrings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
      ],
      child: const CropGuardApp(),
    ),
  );
}

class CropGuardApp extends StatefulWidget {
  const CropGuardApp({super.key});

  @override
  State<CropGuardApp> createState() => _CropGuardAppState();
}

class _CropGuardAppState extends State<CropGuardApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasHandledRecovery = false;

  @override
  void initState() {
    super.initState();
    _listenToAuthEvents();
  }

  void _listenToAuthEvents() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        if (event == AuthChangeEvent.passwordRecovery) {
          // Prevent processing the same recovery callback multiple times
          if (!_hasHandledRecovery) {
            _hasHandledRecovery = true;
            debugPrint('[CropGuard] Supabase AuthChangeEvent.passwordRecovery received');

            // Flag provider so SplashScreen or background listeners do not conflict
            if (mounted) {
              Provider.of<AuthProvider>(context, listen: false).setRecoveryActive(true);
            }

            // Navigate immediately to dedicated Reset Password Screen
            appNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              (route) => false,
            );
          }
        } else if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.signedIn) {
          // Reset flag so subsequent recovery flows can be handled
          _hasHandledRecovery = false;
          if (mounted) {
            Provider.of<AuthProvider>(context, listen: false).setRecoveryActive(false);
          }
        }
      });
    } catch (e) {
      debugPrint('[CropGuard] Auth listener initialization notice: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AppStrings for real-time Telugu / English updates
    context.watch<AppStrings>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
