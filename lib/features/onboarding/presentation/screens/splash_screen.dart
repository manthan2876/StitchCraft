import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool hasSeenLanguage = prefs.getBool('hasSeenLanguage') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (!hasSeenLanguage) {
      Navigator.pushReplacementNamed(context, '/language');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon Placeholder (Using a generic icon as we don't have the asset)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_rounded, // Tailor/Sewing related icon
                size: 80,
                color: AppTheme.primaryColor,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .then(delay: 200.ms)
            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5)),
            
            const SizedBox(height: 24),
            
            // App Name
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 32,
                ),
                children: const [
                  TextSpan(text: 'Stitch'),
                  TextSpan(
                    text: 'Craft',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
