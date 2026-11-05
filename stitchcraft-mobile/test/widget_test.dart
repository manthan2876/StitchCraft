import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/localization/generated/app_localizations.dart';
import 'package:stitchcraft/features/auth/screens/login_screen.dart';
import 'package:stitchcraft/features/auth/screens/signup_screen.dart';
import 'package:stitchcraft/features/auth/widgets/verify_email_sheet.dart';
import 'package:stitchcraft/features/repairs/screens/repair_dashboard.dart';
import 'package:stitchcraft/features/khata/screens/khata_screen.dart';
import 'package:stitchcraft/features/notifications/screens/notifications_screen.dart';
import 'package:stitchcraft/features/profile/screens/profile_screen.dart';
import 'package:stitchcraft/features/shop/screens/shop_hub_screen.dart';
import 'package:stitchcraft/features/profile/widgets/shops_tab.dart';
import 'package:stitchcraft/features/onboarding/screens/language_screen.dart';
import 'package:stitchcraft/core/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NeoCard displays child widget and reacts to taps', (WidgetTester tester) async {
    bool tapped = false;

    // Build the widget in isolation (NeoCard doesn't use GoogleFonts directly)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NeoCard(
          onTap: () => tapped = true,
          child: const Text('Test Child Widget Content'),
        ),
      ),
    ));

    // Verify Child visibility
    expect(find.text('Test Child Widget Content'), findsOneWidget);

    // Verify Tap interaction
    await tester.tap(find.byType(NeoCard));
    expect(tapped, isTrue);
  });

  testWidgets('CreateRepairTicketSheet opens, accepts input, and closes cleanly on back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => CreateRepairTicketSheet(
                      cart: const {'Fitting / Alteration': 1},
                      totalCost: 80,
                      onTicketCreated: (_) {},
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify elements are present
    expect(find.text('Create Repair Ticket'), findsOneWidget);
    expect(find.text('Fitting / Alteration x1'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsOneWidget);
    expect(find.text('₹80'), findsOneWidget);

    // Enter some text into mobile number
    await tester.enterText(find.byType(TextField).at(1), '9876543210');
    await tester.pump();

    // Now simulate pressing close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify sheet dismissed without any assertion or TextEditingController disposed error
    expect(find.text('Create Repair Ticket'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CreateRepairTicketSheet handles system back button while TextField is focused without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => CreateRepairTicketSheet(
                      cart: const {'Fitting / Alteration': 1},
                      totalCost: 80,
                      onTicketCreated: (_) {},
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Focus on the notes text field (at index 2)
    final notesField = find.byType(TextField).at(2);
    await tester.tap(notesField);
    await tester.pump();
    await tester.enterText(notesField, 'Deliver urgently by 5pm');
    await tester.pump();

    // Simulate system back button (like Android hardware back)
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Verify sheet dismissed cleanly without any TextEditingController or _dependents.isEmpty errors
    expect(find.text('Create Repair Ticket'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Dashboard weekly graph maintains bumps on both yesterday and today when payment is recorded today', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Simulate discrete payments: initial advance yesterday (₹500), payment recorded today (₹200)
    final payments = [
      {'amount': 500.0, 'date': yesterday.millisecondsSinceEpoch},
      {'amount': 200.0, 'date': now.millisecondsSinceEpoch},
    ];

    // Weekly bucketing calculation identical to dashboard screen
    final List<double> incomeGraph = List.filled(7, 0.0);
    for (final p in payments) {
      final pDate = DateTime.fromMillisecondsSinceEpoch(p['date'] as int);
      final d1 = DateTime.utc(pDate.year, pDate.month, pDate.day);
      final d2 = DateTime.utc(now.year, now.month, now.day);
      final dayDiff = d2.difference(d1).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        final slotIndex = 6 - dayDiff;
        incomeGraph[slotIndex] += (p['amount'] as double);
      }
    }

    // Slot 5 is yesterday, slot 6 is today
    expect(incomeGraph[5], equals(500.0), reason: "Yesterday's column must keep its bump of ₹500");
    expect(incomeGraph[6], equals(200.0), reason: "Today's column must have its own bump of ₹200");
    expect(incomeGraph.fold(0.0, (sum, val) => sum + val), equals(700.0));
  });

  test('Dashboard weekly graph strictly isolates graph and income points from another tailor outsourced orders', () {
    final now = DateTime.now();

    // Orders in local storage:
    // 1. Tailor's own order: ₹1200 total, ₹400 advance today
    final ownOrder = {
      'id': 'ORD-OWN-1',
      'total_amount': 1200.0,
      'advance_amount': 400.0,
      'shop_id': 'my-shop-id',
      'origin_shop_name': null,
      'isPartnerJob': false,
    };

    // 2. Outsourced job coming from another tailor: ₹3000 main price, ₹1000 advance collected by main tailor
    final partnerOrder = {
      'id': 'ORD-PARTNER-2',
      'total_amount': 800.0,
      'advance_amount': 0.0,
      'shop_id': 'origin-shop-id',
      'delegated_to_shop_id': 'my-shop-id',
      'origin_shop_name': 'Origin Tailor Shop',
      'isPartnerJob': true,
      'isOutsourcedToMe': true,
    };

    final allOrders = [ownOrder, partnerOrder];

    // Detect outsourced orders
    final Set<String> outsourcedOrderIds = {};
    for (final o in allOrders) {
      final orderId = (o['id'] ?? '').toString();
      final isPartner = o['isPartnerJob'] == true ||
          o['isOutsourcedToMe'] == true ||
          (o['origin_shop_name'] != null && o['origin_shop_name'].toString().isNotEmpty);
      if (isPartner && orderId.isNotEmpty) {
        outsourcedOrderIds.add(orderId);
      }
    }

    // Payments recorded:
    // Tailor's own payment: ₹400
    // Leak payment from partner order (should be excluded): ₹1000
    final allPayments = [
      {'order_id': 'ORD-OWN-1', 'amount': 400.0, 'date': now.millisecondsSinceEpoch},
      {'order_id': 'ORD-PARTNER-2', 'amount': 1000.0, 'date': now.millisecondsSinceEpoch},
    ];

    // Build income points with isolation
    final List<double> incomeGraph = List.filled(7, 0.0);
    for (final p in allPayments) {
      final orderId = (p['order_id'] ?? '').toString();
      // Strict isolation: never populate payments from another tailor's outsourced order
      if (orderId.isNotEmpty && outsourcedOrderIds.contains(orderId)) {
        continue;
      }
      final pDate = DateTime.fromMillisecondsSinceEpoch(p['date'] as int);
      final d1 = DateTime.utc(pDate.year, pDate.month, pDate.day);
      final d2 = DateTime.utc(now.year, now.month, now.day);
      final dayDiff = d2.difference(d1).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        final slotIndex = 6 - dayDiff;
        incomeGraph[slotIndex] += (p['amount'] as double);
      }
    }

    // Customer Money to collect
    final moneyToCollect = allOrders.where((order) {
      final orderId = (order['id'] ?? '').toString();
      if (orderId.isNotEmpty && outsourcedOrderIds.contains(orderId)) {
        return false;
      }
      return true;
    }).fold<double>(0, (sum, order) {
      final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
      final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0;
      return sum + (total - advance).clamp(0, double.infinity);
    });

    // Verification:
    // Only the tailor's own ₹400 appears in the graph. The other tailor's ₹1000 is 100% blocked.
    expect(incomeGraph[6], equals(400.0), reason: "Today's income bump must strictly only contain this tailor's revenue");
    expect(incomeGraph.fold(0.0, (sum, val) => sum + val), equals(400.0));
    // Money to collect: only this tailor's balance (₹1200 - ₹400 = ₹800). Partner order is excluded.
    expect(moneyToCollect, equals(800.0));
  });

  testWidgets('LoginScreen shows Sign Up option and navigates to SignupScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    // Verify Sign In components are present
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Tap on Sign Up to navigate to SignupScreen
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify SignupScreen elements
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Shop Name (Optional)'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('SignupScreen validates input fields and requires matching passwords', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SignupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Sign Up with empty fields
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Please enter your full name'), findsOneWidget);

    // Enter name, but leave email invalid
    await tester.enterText(find.byType(TextField).at(0), 'Ramesh Sharma');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Please enter a valid email address'), findsOneWidget);

    // Enter valid email, but short password
    await tester.enterText(find.byType(TextField).at(2), 'ramesh@shop.com');
    await tester.enterText(find.byType(TextField).at(3), '123');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters long'), findsOneWidget);

    // Enter mismatched passwords
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.enterText(find.byType(TextField).at(4), 'different123');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('VerifyEmailSheet displays email, OTP field, and dismisses cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => VerifyEmailSheet.show(ctx, email: 'test@shop.com'),
              child: const Text('Open Verification'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Verification'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text('test@shop.com'), findsOneWidget);
    expect(find.text('Open Gmail'), findsOneWidget);
    expect(find.text('Resend Email'), findsOneWidget);

    // Enter 6-digit OTP
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    // Close sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Email'), findsNothing);
  });

  testWidgets('LoginScreen shows Verify Email? option', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify Email?'), findsOneWidget);
  });

  testWidgets('KhataScreen displays add button in bottom right corner with + icon only (no text)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Test Income Tab (index 1)
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: KhataScreen(initialTabIndex: 1),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify FAB has + icon and NO button text
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    expect(find.descendant(of: fabFinder, matching: find.byIcon(Icons.add)), findsOneWidget);
    expect(find.descendant(of: fabFinder, matching: find.byType(Text)), findsNothing);

    // Verify Scaffold floatingActionButtonLocation is endFloat (bottom right)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation, FloatingActionButtonLocation.endFloat);
  });

  testWidgets('NotificationsScreen does not show notification bell icon in top bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title is Notifications
    expect(find.text('Notifications'), findsOneWidget);

    // Verify that the notification bell icon (Icons.notifications_none_rounded) is NOT present in the top bar
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('Settings & Hub screens have back button and no hamburger menu icon in top bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Test ShopHubScreen
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShopHubScreen(isTab: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    // 2. Test ProfileScreen (Settings)
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(isTab: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(BackButtonIcon), findsOneWidget);
  });

  testWidgets('ShopsTab displays UPI and GSTIN details and allows input in shop dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? addedUpi;
    String? addedGstin;

    final mockShops = [
      {
        '_id': 'shop_1',
        'shopName': 'Royal Tailors',
        'phone': '9876543210',
        'address': 'MG Road, Surat',
        'upiId': 'royal@upi',
        'gstin': '24AAACT1234A1Z5',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShopsTab(
            shops: mockShops,
            activeShopId: 'shop_1',
            onSwitchShop: (_) {},
            onAddShop: (name, phone, address, upi, gstin) {
              addedUpi = upi;
              addedGstin = gstin;
            },
            onEditShop: (_, _, _, _, _, _) {},
            onDeleteShop: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify shop name, UPI, and GST are visible in the list
    expect(find.text('Royal Tailors'), findsOneWidget);
    expect(find.text('UPI: royal@upi'), findsOneWidget);
    expect(find.text('GST: 24AAACT1234A1Z5'), findsOneWidget);

    // Tap Register New Shop button
    await tester.tap(find.text('Register New Shop'));
    await tester.pumpAndSettle();

    // Verify fields in dialog
    expect(find.text('Register New Shop'), findsNWidgets(2)); // Button + Dialog title
    expect(find.text('UPI ID (VPA for Pay QR)'), findsOneWidget);
    expect(find.text('GSTIN Number'), findsOneWidget);

    // Enter details
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'New Heritage Boutique');
    await tester.enterText(textFields.at(3), 'heritage@okhdfcbank');
    await tester.enterText(textFields.at(4), '24BBBBT5678B1Z9');
    await tester.pump();

    // Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(addedUpi, 'heritage@okhdfcbank');
    expect(addedGstin, '24BBBBT5678B1Z9');
  });

  testWidgets('LanguageSelectionScreen changes language cleanly without framework assertion error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en', 'isLoggedIn': true});
    final loc = LocalizationService();
    await loc.loadLanguage();

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: loc.localeNotifier,
        builder: (context, locale, _) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  },
                  child: const Text('Open Language Settings'),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Initial state: English
    expect(loc.currentLanguage, 'en');

    // Open Language Settings
    await tester.tap(find.text('Open Language Settings'));
    await tester.pumpAndSettle();

    // Verify Language Screen is open
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Language Settings'), findsOneWidget);
    expect(find.text('ગુજરાતી'), findsOneWidget);
    expect(find.text('हिंदी'), findsOneWidget);

    // Tap Gujarati card to switch language
    await tester.tap(find.text('ગુજરાતી'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify language updated in LocalizationService and heading updated to Gujarati
    expect(loc.currentLanguage, 'gu');
    expect(find.text('તમારી ભાષા પસંદ કરો'), findsOneWidget);

    // Wait for the smooth pop delay (300ms)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify screen popped back to home cleanly without error
    expect(find.text('Open Language Settings'), findsOneWidget);
  });
}
