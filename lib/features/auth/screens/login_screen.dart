import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/widgets/voice_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: AppTheme.masterjiTheme.textTheme.displayLarge,
              ),
              Text(
                'તમારો મોબાઈલ નંબર નાખો',
                style: AppTheme.masterjiTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              VoiceTextField(
                label: 'Mobile Number',
                controller: _phoneController,
                hint: '9876543210',
                keyboardType: TextInputType.phone,
                onMicTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listening for number...')),
                  );
                },
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Send OTP',
                onPressed: () {
                   // Mock Auth for UI Demo
                   Navigator.pushNamed(context, '/role_selection');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
