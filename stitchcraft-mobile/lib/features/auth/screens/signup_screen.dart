import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/features/auth/widgets/verify_email_sheet.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final shopName = _shopNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (password.length < 6) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.signUp(
        email,
        password,
        name,
        shopName: shopName.isNotEmpty ? shopName : null,
      );

      if (!mounted) return;

      if (result != null && result['requiresVerification'] == true) {
        await VerifyEmailSheet.show(
          context,
          email: email,
          onVerified: () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/shop_setup');
            }
          },
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to StitchCraft.'),
          backgroundColor: AppTheme.trustGreen,
        ),
      );

      // Register device FCM token for push notifications
      NotificationService().registerDeviceTokenWithBackend();

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final currentShopId = prefs.getString('shopId');
      if (currentShopId == null || currentShopId.isEmpty) {
        Navigator.pushReplacementNamed(context, '/shop_setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 48,
                      color: AppTheme.brandPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'StitchCraft',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brandPurple,
                      letterSpacing: 1.2,
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
                const SizedBox(height: 32),
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register your shop to manage orders and measurements',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 20),
                VoiceTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  hint: 'e.g. Ramesh Sharma',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
                VoiceTextField(
                  label: 'Shop Name (Optional)',
                  controller: _shopNameController,
                  hint: 'e.g. Ramesh Tailors',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                VoiceTextField(
                  label: context.loc.email_address,
                  controller: _emailController,
                  hint: 'ramesh@stitchcraft.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                VoiceTextField(
                  label: context.loc.password,
                  controller: _passwordController,
                  hint: '••••••••',
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                VoiceTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  hint: '••••••••',
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.loc.sign_in,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.brandPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
