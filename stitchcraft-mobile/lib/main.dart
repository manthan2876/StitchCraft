import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/firebase_options.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

// Onboarding
import 'package:stitchcraft/features/onboarding/screens/splash_screen.dart';
import 'package:stitchcraft/features/onboarding/screens/language_screen.dart';
import 'package:stitchcraft/features/onboarding/screens/onboarding_carousel_screen.dart';
import 'package:stitchcraft/features/auth/screens/login_screen.dart';
import 'package:stitchcraft/features/auth/screens/role_selection_screen.dart';
import 'package:stitchcraft/features/shop/screens/shop_setup_screen.dart';

// Dashboard
import 'package:stitchcraft/features/dashboard/screens/dashboard_screen.dart';

// Orders
import 'package:stitchcraft/features/orders/screens/create_order/step1_garment.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step2_measurements.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step3_material.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';

import 'package:stitchcraft/core/services/notification_service.dart';

// Modules
import 'package:stitchcraft/features/repairs/screens/repair_dashboard.dart';
import 'package:stitchcraft/features/khata/screens/khata_screen.dart';
import 'package:stitchcraft/features/shop/screens/inventory_screen.dart';
import 'package:stitchcraft/features/shop/screens/karigars_screen.dart';
import 'package:stitchcraft/features/shop/screens/machines_screen.dart';
import 'package:stitchcraft/features/profile/screens/profile_screen.dart';
import 'package:stitchcraft/features/orders/screens/customer_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final isMobile = !kIsWeb && 
      (defaultTargetPlatform == TargetPlatform.android || 
       defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobile) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Initialize Notifications
      final notificationService = NotificationService();
      await notificationService.init();
    } catch (e) {
      debugPrint("Failed to initialize mobile services: $e");
    }
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
      theme: AppTheme.masterjiTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/onboarding': (context) => const OnboardingCarouselScreen(),
        '/login': (context) => const LoginScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/shop_setup': (context) => const ShopSetupScreen(),
        '/home': (context) => const DashboardScreen(),
        
        // Order Wizard
        '/create_order_step1': (context) => const GarmentSelectionScreen(),
        '/create_order_step2': (context) => const MeasurementInputScreen(),
        '/create_order_step3': (context) => const MaterialSelectionScreen(),
        
        // Modules
        '/repairs': (context) => const RepairDashboard(),
        '/khata': (context) => const KhataScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/karigars': (context) => const KarigarsScreen(),
        '/machines': (context) => const MachinesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/customers': (context) => const CustomerListScreen(),
        '/orders_pending': (context) => const OrderListScreen(title: 'Pending Orders', statusFilter: 'pending'),
      },
    );
  }
}
