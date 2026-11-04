import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stitchcraft/core/localization/generated/app_localizations.dart';
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
import 'package:stitchcraft/features/dashboard/screens/more_hub_screen.dart';

// Orders
import 'package:stitchcraft/features/orders/screens/create_order/step1_garment.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step2_customer.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step3_measurements.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step4_material.dart';
import 'package:stitchcraft/features/orders/screens/create_order/step5_details.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';
import 'package:stitchcraft/features/orders/screens/deliveries_screen.dart';

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
import 'package:stitchcraft/features/shop/screens/shop_settings_screen.dart';
import 'package:stitchcraft/features/profile/screens/sync_status_screen.dart';
import 'package:stitchcraft/features/karigar/screens/my_jobs_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitchcraft/core/config/app_env.dart';
import 'package:stitchcraft/core/services/sync_worker.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppEnv.validate();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabaseAnonKey,
  );

  // Load localizations and theme before run
  await LocalizationService().loadLanguage();
  await ThemeService().loadTheme();

  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobile) {
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      developer.log(
        'Firebase initialization failed; push notifications are unavailable',
        name: 'Startup',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final notificationService = NotificationService();
      await notificationService.init();
    } catch (error, stackTrace) {
      developer.log(
        'Notification initialization failed',
        name: 'Startup',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await SyncWorker.initialize();
      await SyncWorker.schedulePeriodicSync();
    } catch (error, stackTrace) {
      developer.log(
        'Background sync initialization failed',
        name: 'Startup',
        error: error,
        stackTrace: stackTrace,
      );
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
              navigatorKey: NotificationService.navigatorKey,
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
                '/more': (context) => const MoreHubScreen(),

                // Order Wizard
                '/create_order_step1': (context) =>
                    const GarmentSelectionScreen(),
                '/create_order_customer': (context) =>
                    const CustomerSelectionScreen(),
                '/create_order_step2': (context) =>
                    const CustomerSelectionScreen(),
                '/create_order_step3': (context) =>
                    const MeasurementInputScreen(),
                '/create_order_step4': (context) =>
                    const MaterialSelectionScreen(),
                '/create_order_step5': (context) =>
                    const OrderConfirmationScreen(),

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
                '/inventory_details': (context) =>
                    const InventoryDetailsScreen(),
                '/invoice_details': (context) => const InvoiceDetailsScreen(),
                '/karigar_details': (context) => const KarigarDetailsScreen(),
                '/orders_pending': (context) => const OrderListScreen(
                  title: 'Pending Orders',
                  statusFilter: 'pending',
                ),
                '/deliveries': (context) => const DeliveriesScreen(),
                '/invoices': (context) => const InvoiceScreen(),
                '/payments': (context) => const KhataScreen(initialTabIndex: 1),
                '/shop_settings': (context) => const ShopSettingsScreen(),
                '/sync_status': (context) => const SyncStatusScreen(),
                '/my_jobs': (context) => const MyJobsScreen(),
              },
            );
          },
        );
      },
    );
  }
}
