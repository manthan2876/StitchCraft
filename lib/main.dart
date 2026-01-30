import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/screens/login/login_screen.dart';
import 'package:stitchcraft/screens/dashboard/dashboard_screen.dart';
import 'package:stitchcraft/screens/login/register_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options for all platforms
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if user session already exists (Requirement: Step 7 of Pr5.pdf)
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(StitchCraftApp(isLoggedIn: isLoggedIn));
}

class StitchCraftApp extends StatelessWidget {
  final bool isLoggedIn;

  const StitchCraftApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StitchCraft',
      debugShowCheckedModeBanner: false,

      // Professional Theme Configuration (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Deep Purple / Tailor Theme
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),

      // Logic to skip Login screen if session exists
      initialRoute: isLoggedIn ? '/dashboard' : '/login',

      // Centralized Route Management
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // Add other routes as you implement them (Measurements, etc.)
      },
    );
  }
}
