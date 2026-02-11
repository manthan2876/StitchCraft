import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/sync_worker.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // minimum splash duration for branding
    final minDuration = Future.delayed(const Duration(seconds: 3));
    
    try {
      // Initialize critical services
      await LocalDatabaseService().database;
      await SyncWorker.initialize();
      await SyncWorker.schedulePeriodicSync();
      await NotificationService().initialize();
    } catch (e) {
      developer.log('Initialization failed: $e');
      // In a real app, you might show a retry dialog here
    }

    await minDuration;
    if (!mounted) return;
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50), // Dark Slate Blue
              Color(0xFF4CA1AF), // Teal-ish
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container
              Container(
                height: 120,
                width: 120,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              )
              .animate()
              .scale(duration: 800.ms, curve: Curves.elasticOut)
              .then(delay: 200.ms)
              .shimmer(duration: 1500.ms, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              
              const SizedBox(height: 32),
              
              // Animated Text
              Column(
                children: [
                   Text(
                    'StitchCraft',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Precision Tailoring Management',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),

              const SizedBox(height: 60),

              // Loading Indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
