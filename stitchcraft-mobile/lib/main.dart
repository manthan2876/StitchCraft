import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/core/localization/generated/app_localizations.dart';
import 'package:stitchcraft/firebase_options.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/localization_service.dart';
import 'package:stitchcraft/core/services/theme_service.dart';

// Onboarding
import 'package:stitchcraft/features/onboarding/screens/splash_screen.dart';
import 'package:stitchcraft/features/onboarding/screens/language_screen.dart';
import 'package:stitchcraft/features/onboarding/screens/onboarding_carousel_screen.dart';
import 'package:stitchcraft/features/auth/screens/login_screen.dart';
import 'package:stitchcraft/features/auth/screens/role_selection_screen.dart';
import 'package:stitchcraft/features/shop/screens/shop_setup_screen.dart';

// Dashboard
import 'package:stitchcraft/features/dashboard/screens/main_navigation_container.dart';

// Orders
import 'package:stitchcraft/features/orders/screens/create_order/step1_garment.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step2_customer.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step3_measurements.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step4_material.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step5_details.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';

import 'package:stitchcraft/core/services/notification_service.dart';

// Modules
import 'package:stitchcraft/features/repairs/screens/repair_dashboard.dart';
import 'package:stitchcraft/features/khata/screens/khata_screen.dart';
import 'package:stitchcraft/features/shop/screens/inventory_screen.dart';
import 'package:stitchcraft/features/shop/screens/karigars_screen.dart';
import 'package:stitchcraft/features/shop/screens/machines_screen.dart';
import 'package:stitchcraft/features/profile/screens/profile_screen.dart';
import 'package:stitchcraft/features/shop/screens/shop_hub_screen.dart';
import 'package:stitchcraft/features/notifications/screens/notifications_screen.dart';
import 'package:stitchcraft/features/orders/screens/customer_list_screen.dart';
import 'package:stitchcraft/features/orders/screens/invoice_screen.dart';
import 'package:stitchcraft/features/orders/screens/order_details_screen.dart';
import 'package:stitchcraft/features/orders/screens/customer_details_screen.dart';
import 'package:stitchcraft/features/shop/screens/machine_details_screen.dart';
import 'package:stitchcraft/features/shop/screens/inventory_details_screen.dart';
import 'package:stitchcraft/features/orders/screens/invoice_details_screen.dart';
import 'package:stitchcraft/features/shop/screens/karigar_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rbpntprbizoqqittxuqc.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJicG50cHJiaXpvcXFpdHR4dXFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3NjAzMzcsImV4cCI6MjA5NzMzNjMzN30.HJS3Q2E6B2ex3lO6qZaSgNtYhQJt1KdiVsRJ8tyyus4',
  );
  
  // Load localizations and theme before run
  await LocalizationService().loadLanguage();
  await ThemeService().loadTheme();

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
    final loc = LocalizationService();

    return ValueListenableBuilder<Locale>(
      valueListenable: loc.localeNotifier,
      builder: (context, currentLocale, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService().themeNotifier,
          builder: (context, currentThemeMode, child) {
            return MaterialApp(
              title: 'StitchCraft',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.masterjiTheme,
              themeMode: currentThemeMode,
              initialRoute: '/',
              locale: currentLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routes: {
                '/': (context) => const SplashScreen(),
                '/language': (context) => const LanguageSelectionScreen(),
                '/onboarding': (context) => const OnboardingCarouselScreen(),
                '/login': (context) => const LoginScreen(),
                '/role_selection': (context) => const RoleSelectionScreen(),
                '/shop_setup': (context) => const ShopSetupScreen(),
                '/home': (context) => const MainNavigationContainer(),
                
                // Order Wizard
                '/create_order_step1': (context) => const GarmentSelectionScreen(),
                '/create_order_step2': (context) => const CustomerSelectionScreen(),
                '/create_order_step3': (context) => const MeasurementInputScreen(),
                '/create_order_step4': (context) => const MaterialSelectionScreen(),
                '/create_order_step5': (context) => const OrderConfirmationScreen(),
                
                // Modules
                '/repairs': (context) => const RepairDashboard(),
                '/khata': (context) => const KhataScreen(initialTabIndex: 0),
                '/inventory': (context) => const InventoryScreen(),
                '/karigars': (context) => const KarigarsScreen(),
                '/machines': (context) => const MachinesScreen(),
                '/profile': (context) => const ProfileScreen(),
                '/shop_hub': (context) => const ShopHubScreen(),
                '/notifications': (context) => const NotificationsScreen(),
                '/customers': (context) => const CustomerListScreen(),
                '/order_details': (context) => const OrderDetailsScreen(),
                '/customer_details': (context) => const CustomerDetailsScreen(),
                '/machine_details': (context) => const MachineDetailsScreen(),
                '/inventory_details': (context) => const InventoryDetailsScreen(),
                '/invoice_details': (context) => const InvoiceDetailsScreen(),
                '/karigar_details': (context) => const KarigarDetailsScreen(),
                '/orders_pending': (context) => const OrderListScreen(title: 'Pending Orders', statusFilter: 'pending'),
                '/deliveries': (context) => const OrderListScreen(title: 'Deliveries', statusFilter: 'completed'),
                '/invoices': (context) => const InvoiceScreen(),
                '/payments': (context) => const KhataScreen(initialTabIndex: 1),
              },
            );
          },
        );
      },
    );
  }
}
