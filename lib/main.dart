import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/screens/login/login_screen.dart';
import 'package:stitchcraft/screens/dashboard/dashboard_screen.dart';
import 'package:stitchcraft/screens/login/register_screen.dart';
import 'package:stitchcraft/screens/customers/customer_list_screen.dart';
import 'package:stitchcraft/screens/orders/order_list_screen.dart';
import 'package:stitchcraft/screens/measurements/measurement_screen.dart';
import 'package:stitchcraft/firebase_options.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import 'package:stitchcraft/screens/home_navigation_screen.dart';
import 'package:stitchcraft/screens/login/forgot_password_screen.dart';
import 'package:stitchcraft/screens/login/otp_verification_screen.dart';
import 'package:stitchcraft/screens/login/new_password_screen.dart';
import 'package:stitchcraft/screens/login/password_success_screen.dart';
import 'package:stitchcraft/screens/onboarding/splash_screen.dart';
import 'package:stitchcraft/screens/onboarding/language_screen.dart';
import 'package:stitchcraft/screens/onboarding/shop_setup_screen.dart';
import 'package:stitchcraft/screens/onboarding/role_selection_screen.dart';
import 'package:stitchcraft/screens/dashboard/staff_dashboard_screen.dart';
import 'package:stitchcraft/screens/customers/customer_list_screen.dart';
import 'package:stitchcraft/screens/customers/client_profile_screen.dart';
import 'package:stitchcraft/screens/customers/edit_client_screen.dart';
import 'package:stitchcraft/screens/profile_screen.dart';
import 'package:stitchcraft/screens/orders/order_list_screen.dart';
import 'package:stitchcraft/screens/orders/order_wizard_screen.dart';
import 'package:stitchcraft/screens/orders/garment_specs_screen.dart';
import 'package:stitchcraft/screens/orders/fabric_capture_screen.dart';
import 'package:stitchcraft/screens/measurements/measurement_screen.dart';
import 'package:stitchcraft/screens/measurements/measurement_selector_screen.dart';
import 'package:stitchcraft/screens/measurements/visual_measurement_screen.dart';
import 'package:stitchcraft/screens/measurements/measurement_form_screen.dart';
import 'package:stitchcraft/screens/financials/expense_screen.dart';
import 'package:stitchcraft/screens/financials/invoice_screen.dart';
import 'package:stitchcraft/screens/inventory/inventory_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options for all platforms
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optionally route Firebase calls to local emulators when enabled at runtime.
  const bool useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );

  if (useEmulator) {
    try {
      if (kDebugMode) {
        debugPrint('Using Firebase emulators');
      }
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'stitchcraft',
      ).useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      debugPrint('Failed to configure Firebase emulators: $e');
    }
  }

  // Enable Firestore persistence for offline support
  try {
    FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'stitchcraft',
    ).settings = const Settings(persistenceEnabled: true);
  } catch (_) {
    // Ignore errors for unsupported platforms
  }

  runApp(const StitchCraftApp());
}

class StitchCraftApp extends StatelessWidget {
  const StitchCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StitchCraft',
      debugShowCheckedModeBanner: false,

      // Apply the Custom App Theme
      theme: AppTheme.lightTheme,

      // Navigation Logic
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Onboarding
        '/shop_setup': (context) => const ShopSetupScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        
        // Dashboards
        '/home': (context) => const HomeNavigationScreen(), // Admin Nav
        '/staff_dashboard': (context) => const StaffDashboardScreen(),
        
        // CRM
        '/customers': (context) => const CustomerListScreen(),
        '/client_profile': (context) => const ClientProfileScreen(),
        '/edit_client': (context) => const EditClientScreen(),
        '/profile': (context) => const ProfileScreen(), // App Profile
        
        // Measurements
        '/measurements': (context) => const MeasurementListScreen(),
        '/measurement_selector': (context) => const MeasurementSelectorScreen(),
        '/visual_measurement': (context) => const VisualMeasurementScreen(),
        '/measurement_form': (context) => const MeasurementFormScreen(),
        
        // Orders
        '/orders': (context) => const OrderListScreen(),
        '/order_wizard': (context) => const OrderWizardScreen(),
        '/garment_specs': (context) => const GarmentSpecsScreen(),
        '/fabric_capture': (context) => const FabricCaptureScreen(),
        
        // Financials & Inventory
        '/expenses': (context) => const ExpenseScreen(),
        '/invoices': (context) => const InvoiceScreen(),
        '/inventory': (context) => const InventoryScreen(),
      },
    );
  }
}