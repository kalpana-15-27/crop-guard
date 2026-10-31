import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signIn(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _handleForgotPassword() {
    final tr = AppStrings().tr;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('emailHint')),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('forgotPassword')),
        content: Text('Send password reset instructions to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final ok = await auth.sendPasswordReset(email);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Reset link sent!' : (auth.errorMessage ?? 'Failed')),
                  backgroundColor: ok ? AppTheme.leafGreen : AppTheme.errorRed,
                ),
              );
            },
            child: Text(tr('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final auth = Provider.of<AuthProvider>(context);
    final isTe = AppStrings().isTelugu;

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('appName')),
        actions: [
          TextButton.icon(
            onPressed: () {
              AppStrings().setLanguage(isTe ? 'en' : 'te');
              setState(() {});
            },
            icon: const Icon(Icons.language, size: 18, color: AppTheme.leafGreen),
            label: Text(
              isTe ? 'English' : 'తెలుగు',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.leafGreen),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.leafGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.eco, size: 40, color: AppTheme.leafGreen),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('loginTitle'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('loginSubtitle'),
                  style: const TextStyle(fontSize: 14, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 32),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: tr('email'),
                  hint: tr('emailHint'),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return tr('invalidEmail');
                    if (!v.contains('@') || !v.contains('.')) return tr('invalidEmail');
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: tr('password'),
                  hint: tr('passwordHint'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return tr('passwordTooShort');
                    return null;
                  },
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(tr('forgotPassword')),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: tr('loginButton'),
                  isLoading: auth.isLoading,
                  icon: Icons.login,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 28),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('dontHaveAccount'),
                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        tr('signUp'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
