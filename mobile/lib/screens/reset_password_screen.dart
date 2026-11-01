import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../localization/app_strings.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

/// Screen allowing farmers to set a new password after opening a recovery deep link
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasActiveRecoverySession {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null;
  }

  Future<void> _handleSavePassword() async {
    final tr = AppStrings().tr;
    if (!_formKey.currentState!.validate()) return;

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = tr('passwordsDoNotMatch');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Sign out recovery session cleanly so user logs in afresh
      await supabase.auth.signOut();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      // Show success dialog and navigate to login
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.leafGreen, size: 28),
              SizedBox(width: 10),
              Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            tr('passwordResetSuccess'),
            style: const TextStyle(fontSize: 15, color: AppTheme.darkText),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.leafGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(tr('signIn')),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings().tr;
    final isTe = AppStrings().isTelugu;

    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        title: Text(tr('appName')),
        automaticallyImplyLeading: false,
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
          child: !_hasActiveRecoverySession && !_isSuccess
              ? _buildExpiredOrInvalidView(tr)
              : _buildResetForm(tr),
        ),
      ),
    );
  }

  Widget _buildExpiredOrInvalidView(String Function(String) tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.warningAmber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.link_off, size: 44, color: AppTheme.warningAmber),
        ),
        const SizedBox(height: 24),
        Text(
          tr('resetPasswordTitle'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('invalidRecoveryLink'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppTheme.mutedText, height: 1.4),
        ),
        const SizedBox(height: 36),
        CustomButton(
          text: tr('signIn'),
          icon: Icons.arrow_back,
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildResetForm(String Function(String) tr) {
    return Form(
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
                color: AppTheme.leafGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_reset, size: 40, color: AppTheme.leafGreen),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('resetPasswordTitle'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('resetPasswordSubtitle'),
            style: const TextStyle(fontSize: 14, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 28),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // New Password
          CustomTextField(
            controller: _newPasswordController,
            label: tr('newPassword'),
            hint: tr('newPasswordHint'),
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.mutedText,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 6) {
                return tr('passwordTooShort');
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm New Password
          CustomTextField(
            controller: _confirmPasswordController,
            label: tr('confirmPassword'),
            hint: tr('confirmPasswordHint'),
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.mutedText,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return tr('passwordsDoNotMatch');
              }
              if (v.trim() != _newPasswordController.text.trim()) {
                return tr('passwordsDoNotMatch');
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: tr('saveNewPassword'),
            isLoading: _isLoading,
            icon: Icons.check,
            onPressed: _handleSavePassword,
          ),
          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(tr('signIn')),
            ),
          ),
        ],
      ),
    );
  }
}
