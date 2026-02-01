import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 100,
                    color: AppTheme.successColor,
                  ),
                ).animate().scale(curve: Curves.elasticOut),
                const SizedBox(height: 32),
              
              Text(
                'Password Recover Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Return to the login screen to enter the application',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  child: const Text('Return to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
