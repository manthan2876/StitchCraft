import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/screens/login/login_screen.dart';
import 'package:stitchcraft/screens/dashboard/dashboard_screen.dart';
import 'package:stitchcraft/screens/login/register_screen.dart';
import 'firebase_options.dart';
import 'package:stitchcraft/screens/customers/customer_list_screen.dart';
import 'package:stitchcraft/screens/orders/order_list_screen.dart';
import 'package:stitchcraft/screens/measurements/measurement_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options for all platforms
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optionally route Firebase calls to local emulators when enabled at runtime.
  // Enable by passing: --dart-define=USE_FIREBASE_EMULATOR=true when running the app.
  // This will connect to Firestore database "stitchcraft" on the emulator.
  const bool useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );
  if (useEmulator) {
    // Firestore emulator defaults to localhost:8080 and Auth emulator to localhost:9099
    // Database name: "stitchcraft"
    try {
      if (kDebugMode) {
        // Only log in debug mode to avoid leaking info in production
        // ignore: avoid_print
        print(
          'Using Firebase emulators (Firestore: localhost:8080, Auth: localhost:9099)',
        );
      }
      // Use the named Firestore database instance. This targets the
      // Firestore database you created named 'stitchcraft'.
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'stitchcraft',
      ).useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // If emulator APIs are not available or fail, log and continue.
      // ignore: avoid_print
      print('Failed to configure Firebase emulators: $e');
    }
  }

  // Enable Firestore persistence for offline support
  try {
    FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'stitchcraft',
    ).settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {
    // Ignore errors for unsupported platforms
  }

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
        '/customers': (context) => CustomerListScreen(),
        '/orders': (context) => OrderListScreen(),
        '/measurements': (context) => MeasurementScreen(),
      },
    );
  }
}
