import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'StitchCraft Dashboard'**
  String get dashboard_title;

  /// No description provided for @cash_reserve.
  ///
  /// In en, this message translates to:
  /// **'Cash Reserve'**
  String get cash_reserve;

  /// No description provided for @pending_orders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pending_orders;

  /// No description provided for @weekly_output.
  ///
  /// In en, this message translates to:
  /// **'Weekly Stitching Output'**
  String get weekly_output;

  /// No description provided for @performance_summary.
  ///
  /// In en, this message translates to:
  /// **'Aggregated metrics tracking current segment data'**
  String get performance_summary;

  /// No description provided for @new_order.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get new_order;

  /// No description provided for @khata_ledger.
  ///
  /// In en, this message translates to:
  /// **'Khata Ledger'**
  String get khata_ledger;

  /// No description provided for @inventory_stock.
  ///
  /// In en, this message translates to:
  /// **'Inventory Stock'**
  String get inventory_stock;

  /// No description provided for @tailoring_staff.
  ///
  /// In en, this message translates to:
  /// **'Tailoring Staff'**
  String get tailoring_staff;

  /// No description provided for @repair_jobs.
  ///
  /// In en, this message translates to:
  /// **'Repair Jobs'**
  String get repair_jobs;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @home_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Home Dashboard'**
  String get home_dashboard;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @billing_dispatch.
  ///
  /// In en, this message translates to:
  /// **'Billing & Dispatch'**
  String get billing_dispatch;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @karigars.
  ///
  /// In en, this message translates to:
  /// **'Karigars'**
  String get karigars;

  /// No description provided for @machines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machines;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @shop_settings.
  ///
  /// In en, this message translates to:
  /// **'Shop Settings'**
  String get shop_settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @language_settings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get language_settings;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @record_new_expense.
  ///
  /// In en, this message translates to:
  /// **'Record New Expense'**
  String get record_new_expense;

  /// No description provided for @expense_category_hint.
  ///
  /// In en, this message translates to:
  /// **'Expense Category (e.g., Fabric, Rent, Utilities)'**
  String get expense_category_hint;

  /// No description provided for @amount_rs.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amount_rs;

  /// No description provided for @short_description.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get short_description;

  /// No description provided for @add_expense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get add_expense;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
