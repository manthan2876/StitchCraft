import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      await _authService.login(email, password);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.login_successful),
          backgroundColor: AppTheme.trustGreen,
        ),
      );
      // Register FCM device token with backend now that user is authenticated
      NotificationService().registerDeviceTokenWithBackend();

      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getString('shopId');
      if (shopId == null || shopId.isEmpty) {
        Navigator.pushReplacementNamed(context, '/shop_setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.loc.login_failed}: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final messenger = ScaffoldMessenger.of(context);
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogInnerCtx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(dialogInnerCtx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            context.loc.reset_password,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(dialogInnerCtx).textTheme.titleLarge?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.reset_password_instructions,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.loc.email_address,
                  hintText: 'name@shop.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(dialogCtx).pop(),
              child: Text(context.loc.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(context.loc.enter_email_warning),
                            backgroundColor: AppTheme.alertRed,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      try {
                        await _authService.sendPasswordResetEmail(email);
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${context.loc.password_reset_sent} $email'),
                            backgroundColor: AppTheme.trustGreen,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${context.loc.failed}: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppTheme.alertRed,
                          ),
                        );
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(context.loc.send_link),
            ),
          ],
        ),
      ),
    );
    resetEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 64,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'StitchCraft',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brandPurple,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    context.loc.tailor_business_management,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  context.loc.sign_in,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                VoiceTextField(
                  label: context.loc.email_address,
                  controller: _emailController,
                  hint: 'ramesh@stitchcraft.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                VoiceTextField(
                  label: context.loc.password,
                  controller: _passwordController,
                  hint: '••••••••',
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.loc.forgot_password,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.brandPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: context.loc.sign_in,
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
