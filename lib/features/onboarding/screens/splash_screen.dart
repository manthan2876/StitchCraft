import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/language');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Placeholder (Yellow Thread Spool)
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppTheme.marigold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.content_cut, // Placeholder for Spool/Needle
                size: 60,
                color: AppTheme.navyBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'StitchCraft',
              style: AppTheme.masterjiTheme.textTheme.displayLarge,
            ),
            Text(
              'Made for Bharat',
              style: AppTheme.masterjiTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            // Loader
            const CircularProgressIndicator(
              color: AppTheme.marigold,
            ),
          ],
        ),
      ),
    );
  }
}
