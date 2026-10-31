import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editNameDialog(BuildContext context, AuthProvider auth) {
    final tr = AppStrings().tr;
    final controller = TextEditingController(text: auth.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('fullName')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: tr('fullNameHint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await SupabaseAuthService().updateProfile(fullName: newName);
                await auth.loadProfile();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider auth) {
    final tr = AppStrings().tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('logout')),
        content: Text(tr('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(tr('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final strings = AppStrings();
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('profileTitle')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.leafGreen.withValues(alpha: 0.12),
                      child: Text(
                        auth.displayName.isNotEmpty
                            ? auth.displayName[0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  auth.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.leafGreen),
                                onPressed: () => _editNameDialog(context, auth),
                              ),
                            ],
                          ),
                          Text(
                            auth.userEmail.isNotEmpty ? auth.userEmail : 'authenticated farmer',
                            style: const TextStyle(fontSize: 13, color: AppTheme.mutedText),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified Farmer Account',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.leafGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language Selection Card
              Text(
                tr('preferredLanguage'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkText),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 1),
                ),
                child: RadioGroup<String>(
                  groupValue: strings.currentLanguage,
                  onChanged: (val) {
                    if (val != null) {
                      strings.setLanguage(val);
                      SupabaseAuthService().updateProfile(preferredLanguage: val);
                      setState(() {});
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'en',
                        activeColor: AppTheme.leafGreen,
                        title: Text('English (Default)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('All diagnostics and advice in English', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                      ),
                      Divider(height: 1, color: AppTheme.borderLight),
                      RadioListTile<String>(
                        value: 'te',
                        activeColor: AppTheme.leafGreen,
                        title: Text('తెలుగు (Telugu)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('పురుగుల గుర్తింపు మరియు నివారణ చర్యలు తెలుగులో', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Information Card
              Text(
                tr('appInfo'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.darkText),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.leafGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_outlined, color: AppTheme.leafGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkText),
                            ),
                            Text(
                              'Version ${AppConfig.appVersion} (${AppConfig.modelVersion})',
                              style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr('appInfoDescription'),
                      style: const TextStyle(fontSize: 13, color: AppTheme.darkText, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_outlined, size: 16, color: AppTheme.freshGreen),
                        SizedBox(width: 6),
                        Text(
                          'Supabase Cloud & PostgreSQL RLS Connected',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign Out Button
              CustomButton(
                text: tr('logout'),
                icon: Icons.logout,
                variant: ButtonVariant.outlined,
                onPressed: () => _handleLogout(context, auth),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
