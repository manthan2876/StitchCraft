import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:stitchcraft/firebase_options.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

// Features
import 'package:stitchcraft/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:stitchcraft/features/onboarding/presentation/screens/language_screen.dart';
import 'package:stitchcraft/features/onboarding/presentation/screens/shop_setup_screen.dart';
import 'package:stitchcraft/features/onboarding/presentation/screens/role_selection_screen.dart';
import 'package:stitchcraft/features/auth/presentation/screens/login_screen.dart';
import 'package:stitchcraft/features/auth/presentation/screens/register_screen.dart';
import 'package:stitchcraft/features/auth/presentation/auth_provider.dart' as app_auth;
import 'package:stitchcraft/features/dashboard/presentation/screens/bento_dashboard_screen.dart';
import 'package:stitchcraft/features/dashboard/presentation/screens/grid_dashboard_screen.dart';
import 'package:stitchcraft/features/dashboard/presentation/screens/home_navigation_screen.dart';
import 'package:stitchcraft/features/dashboard/presentation/screens/staff_dashboard_screen.dart';
import 'package:stitchcraft/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:stitchcraft/features/customers/presentation/screens/client_profile_screen.dart';
import 'package:stitchcraft/features/customers/presentation/screens/edit_client_screen.dart';
import 'package:stitchcraft/features/profile/presentation/screens/profile_screen.dart';
import 'package:stitchcraft/features/measurements/presentation/screens/haptic_measurement_screen.dart';
import 'package:stitchcraft/features/orders/presentation/screens/order_list_screen.dart';
import 'package:stitchcraft/features/orders/presentation/screens/order_wizard_screen.dart';
import 'package:stitchcraft/features/orders/presentation/screens/garment_specs_screen.dart';
import 'package:stitchcraft/features/orders/presentation/screens/fabric_capture_screen.dart';
import 'package:stitchcraft/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:stitchcraft/features/finances/presentation/screens/enhanced_khata_screen.dart';
import 'package:stitchcraft/features/repairs/presentation/screens/fast_lane_repairs_screen.dart';
import 'package:stitchcraft/features/auth/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Offline-First Infrastructure
  // Core services are now initialized in SplashScreen to show UI immediately
  
  const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  if (useEmulator) {
    try {
      if (kDebugMode) debugPrint('Using Firebase emulators');
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'stitchcraft').useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      debugPrint('Failed to configure Firebase emulators: $e');
    }
  }

  try {
    FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'stitchcraft').settings = const Settings(persistenceEnabled: true);
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
      ],
      child: const StitchCraftApp(),
    ),
  );
}

class StitchCraftApp extends StatelessWidget {
  const StitchCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StitchCraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/shop_setup': (context) => const ShopSetupScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/home': (context) => const BentoDashboardScreen(),
        '/grid_dashboard': (context) => const GridDashboardScreen(),
        '/home_nav': (context) => const HomeNavigationScreen(),
        '/staff_dashboard': (context) => const StaffDashboardScreen(),
        '/customers': (context) => const CustomerListScreen(),
        '/client_profile': (context) => const ClientProfileScreen(),
        '/edit_client': (context) => const EditClientScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/measurements': (context) => const HapticMeasurementScreen(),
        '/orders': (context) => const OrderListScreen(),
        '/order_wizard': (context) => const OrderWizardScreen(),
        '/garment_specs': (context) => const GarmentSpecsScreen(),
        '/fabric_capture': (context) => const FabricCaptureScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/khata': (context) => const EnhancedKhataScreen(),
        '/repairs': (context) => const FastLaneRepairsScreen(),
        '/portfolio': (context) => Scaffold(
          appBar: AppBar(title: const Text('Portfolio')),
          body: const Center(child: Text('Portfolio feature coming soon')),
        ),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
