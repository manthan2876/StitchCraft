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

  /// No description provided for @download_gdpr.
  ///
  /// In en, this message translates to:
  /// **'Download All Data (GDPR)'**
  String get download_gdpr;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Request'**
  String get delete_account;

  /// No description provided for @add_staff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get add_staff;

  /// No description provided for @edit_staff.
  ///
  /// In en, this message translates to:
  /// **'Edit Tailoring Staff'**
  String get edit_staff;

  /// No description provided for @add_machine.
  ///
  /// In en, this message translates to:
  /// **'Add Machine'**
  String get add_machine;

  /// No description provided for @edit_machine.
  ///
  /// In en, this message translates to:
  /// **'Edit Machine Info'**
  String get edit_machine;

  /// No description provided for @add_material.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get add_material;

  /// No description provided for @edit_material.
  ///
  /// In en, this message translates to:
  /// **'Edit Material Info'**
  String get edit_material;

  /// No description provided for @recent_orders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recent_orders;

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Shop Chat'**
  String get chat;

  /// No description provided for @shop_hub.
  ///
  /// In en, this message translates to:
  /// **'Shop Hub'**
  String get shop_hub;

  /// No description provided for @register_order.
  ///
  /// In en, this message translates to:
  /// **'Register Order'**
  String get register_order;

  /// No description provided for @manage_ledger.
  ///
  /// In en, this message translates to:
  /// **'Manage Ledger'**
  String get manage_ledger;

  /// No description provided for @staff_directory.
  ///
  /// In en, this message translates to:
  /// **'Staff Directory'**
  String get staff_directory;

  /// No description provided for @track_stock.
  ///
  /// In en, this message translates to:
  /// **'Track Stock'**
  String get track_stock;

  /// No description provided for @ready_deliveries.
  ///
  /// In en, this message translates to:
  /// **'Ready to Deliver'**
  String get ready_deliveries;

  /// No description provided for @udhar_ledger.
  ///
  /// In en, this message translates to:
  /// **'Udhar'**
  String get udhar_ledger;

  /// No description provided for @total_udhar_outstanding.
  ///
  /// In en, this message translates to:
  /// **'TOTAL UDHAR OUTSTANDING'**
  String get total_udhar_outstanding;

  /// No description provided for @orders_with_balance.
  ///
  /// In en, this message translates to:
  /// **'orders with balance'**
  String get orders_with_balance;

  /// No description provided for @no_udhar_balances.
  ///
  /// In en, this message translates to:
  /// **'No pending balances (Udhar)!'**
  String get no_udhar_balances;

  /// No description provided for @all_orders_paid.
  ///
  /// In en, this message translates to:
  /// **'All customer orders are fully paid up.'**
  String get all_orders_paid;

  /// No description provided for @send_whatsapp_reminder.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp Reminder'**
  String get send_whatsapp_reminder;

  /// No description provided for @order_num.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get order_num;

  /// No description provided for @due_amount.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due_amount;

  /// No description provided for @paid_amount.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid_amount;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total_amount;

  /// No description provided for @sync_offline_status.
  ///
  /// In en, this message translates to:
  /// **'Sync & Offline Status'**
  String get sync_offline_status;

  /// No description provided for @refresh_status.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refresh_status;

  /// No description provided for @all_changes_synced.
  ///
  /// In en, this message translates to:
  /// **'All Changes Synced'**
  String get all_changes_synced;

  /// No description provided for @pending_local_changes.
  ///
  /// In en, this message translates to:
  /// **'Pending Local Changes'**
  String get pending_local_changes;

  /// No description provided for @last_sync.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get last_sync;

  /// No description provided for @sync_now_cloud.
  ///
  /// In en, this message translates to:
  /// **'Sync Now with Cloud'**
  String get sync_now_cloud;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @local_queue_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Local Queue Breakdown'**
  String get local_queue_breakdown;

  /// No description provided for @expenses_khata.
  ///
  /// In en, this message translates to:
  /// **'Expenses & Khata'**
  String get expenses_khata;

  /// No description provided for @inventory_materials.
  ///
  /// In en, this message translates to:
  /// **'Inventory Materials'**
  String get inventory_materials;

  /// No description provided for @failed_records.
  ///
  /// In en, this message translates to:
  /// **'Failed Records'**
  String get failed_records;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @sync_success.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully!'**
  String get sync_success;

  /// No description provided for @just_now.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get just_now;

  /// No description provided for @never_synced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get never_synced;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @email_address.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_address;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password;

  /// No description provided for @reset_password_instructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address to receive a password reset link.'**
  String get reset_password_instructions;

  /// No description provided for @send_link.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get send_link;

  /// No description provided for @login_successful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful! Welcome to StitchCraft.'**
  String get login_successful;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get login_failed;

  /// No description provided for @choose_role.
  ///
  /// In en, this message translates to:
  /// **'Choose Role'**
  String get choose_role;

  /// No description provided for @who_are_you.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get who_are_you;

  /// No description provided for @shop_owner_masterji.
  ///
  /// In en, this message translates to:
  /// **'Shop Owner (Masterji)'**
  String get shop_owner_masterji;

  /// No description provided for @full_access.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get full_access;

  /// No description provided for @staff_karigar.
  ///
  /// In en, this message translates to:
  /// **'Staff (Karigar)'**
  String get staff_karigar;

  /// No description provided for @tasks_only.
  ///
  /// In en, this message translates to:
  /// **'Tasks Only'**
  String get tasks_only;

  /// No description provided for @no_orders_found.
  ///
  /// In en, this message translates to:
  /// **'No orders matching filters.'**
  String get no_orders_found;

  /// No description provided for @no_customers_found.
  ///
  /// In en, this message translates to:
  /// **'No customers registered yet.'**
  String get no_customers_found;

  /// No description provided for @order_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get order_details;

  /// No description provided for @invoice_details.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoice_details;

  /// No description provided for @share_bill.
  ///
  /// In en, this message translates to:
  /// **'Share Bill'**
  String get share_bill;

  /// No description provided for @send_reminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get send_reminder;

  /// No description provided for @download_pdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get download_pdf;

  /// No description provided for @send_pdf.
  ///
  /// In en, this message translates to:
  /// **'Send PDF'**
  String get send_pdf;

  /// No description provided for @total_charges.
  ///
  /// In en, this message translates to:
  /// **'Total Charges'**
  String get total_charges;

  /// No description provided for @balance_amount_due.
  ///
  /// In en, this message translates to:
  /// **'Balance Amount Due'**
  String get balance_amount_due;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @tailor_business_management.
  ///
  /// In en, this message translates to:
  /// **'Tailor Business Management'**
  String get tailor_business_management;

  /// No description provided for @enter_email_warning.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get enter_email_warning;

  /// No description provided for @password_reset_sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to'**
  String get password_reset_sent;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @shops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get shops;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @settings_and_hub.
  ///
  /// In en, this message translates to:
  /// **'Settings & Hub'**
  String get settings_and_hub;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated Successfully!'**
  String get profile_updated;

  /// No description provided for @password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully!'**
  String get password_changed;

  /// No description provided for @shop_updated.
  ///
  /// In en, this message translates to:
  /// **'Shop updated successfully'**
  String get shop_updated;

  /// No description provided for @fast_lane_repairs.
  ///
  /// In en, this message translates to:
  /// **'Fast Lane Repairs'**
  String get fast_lane_repairs;

  /// No description provided for @import_contacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from Mobile Contacts'**
  String get import_contacts;

  /// No description provided for @save_contact_to_phone.
  ///
  /// In en, this message translates to:
  /// **'Save contact in your phone'**
  String get save_contact_to_phone;

  /// No description provided for @already_in_contacts.
  ///
  /// In en, this message translates to:
  /// **'Already saved in your phone contacts'**
  String get already_in_contacts;

  /// No description provided for @select_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Select Phone Number'**
  String get select_phone_number;

  /// No description provided for @contact_saved_to_phone.
  ///
  /// In en, this message translates to:
  /// **'Contact saved to your phone'**
  String get contact_saved_to_phone;

  /// No description provided for @add_customer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get add_customer;

  /// No description provided for @customer_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customer_added_successfully;

  /// No description provided for @onboarding_measurements_title.
  ///
  /// In en, this message translates to:
  /// **'Keep measurements safe'**
  String get onboarding_measurements_title;

  /// No description provided for @onboarding_measurements_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Save customer measurements digitally, even when your shop is offline.'**
  String get onboarding_measurements_subtitle;

  /// No description provided for @onboarding_khata_title.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of udhar'**
  String get onboarding_khata_title;

  /// No description provided for @onboarding_khata_subtitle.
  ///
  /// In en, this message translates to:
  /// **'See who owes you money and send WhatsApp reminders in seconds.'**
  String get onboarding_khata_subtitle;

  /// No description provided for @onboarding_orders_title.
  ///
  /// In en, this message translates to:
  /// **'Run every order clearly'**
  String get onboarding_orders_title;

  /// No description provided for @onboarding_orders_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track stitching, delivery dates, payments, and workshop assignments in one place.'**
  String get onboarding_orders_subtitle;

  /// No description provided for @onboarding_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboarding_next;

  /// No description provided for @onboarding_start.
  ///
  /// In en, this message translates to:
  /// **'Create your shop'**
  String get onboarding_start;

  /// No description provided for @dashboard_data_local.
  ///
  /// In en, this message translates to:
  /// **'Showing saved shop data. Pull to refresh when you are online.'**
  String get dashboard_data_local;

  /// No description provided for @dashboard_chart_summary.
  ///
  /// In en, this message translates to:
  /// **'Orders created in the selected period'**
  String get dashboard_chart_summary;

  /// No description provided for @no_customers_action.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer'**
  String get no_customers_action;

  /// No description provided for @sync_status_title.
  ///
  /// In en, this message translates to:
  /// **'Sync Status & Offline Data'**
  String get sync_status_title;

  /// No description provided for @deliver_unpaid_warning.
  ///
  /// In en, this message translates to:
  /// **'Deliver with unpaid balance?'**
  String get deliver_unpaid_warning;

  /// No description provided for @deliver_unpaid_message.
  ///
  /// In en, this message translates to:
  /// **'This order has an outstanding balance. Are you sure you want to mark it as Delivered?'**
  String get deliver_unpaid_message;

  /// No description provided for @danger_zone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get danger_zone;

  /// No description provided for @delete_shop.
  ///
  /// In en, this message translates to:
  /// **'Delete Shop'**
  String get delete_shop;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @saved_on_phone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get saved_on_phone;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @due_today.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get due_today;

  /// No description provided for @late_orders.
  ///
  /// In en, this message translates to:
  /// **'Late Orders'**
  String get late_orders;

  /// No description provided for @collect_money.
  ///
  /// In en, this message translates to:
  /// **'Collect Money'**
  String get collect_money;

  /// No description provided for @start_new_order.
  ///
  /// In en, this message translates to:
  /// **'Start New Order'**
  String get start_new_order;

  /// No description provided for @next_up.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get next_up;

  /// No description provided for @search_orders.
  ///
  /// In en, this message translates to:
  /// **'Search customer or order'**
  String get search_orders;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @all_stages.
  ///
  /// In en, this message translates to:
  /// **'All Stages'**
  String get all_stages;

  /// No description provided for @create_first_order.
  ///
  /// In en, this message translates to:
  /// **'Create First Order'**
  String get create_first_order;

  /// No description provided for @find_customer.
  ///
  /// In en, this message translates to:
  /// **'Find Customer'**
  String get find_customer;

  /// No description provided for @walk_in_customer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walk_in_customer;

  /// No description provided for @reuse_measurements.
  ///
  /// In en, this message translates to:
  /// **'Reuse Measurements'**
  String get reuse_measurements;

  /// No description provided for @add_garment.
  ///
  /// In en, this message translates to:
  /// **'Add Garment'**
  String get add_garment;

  /// No description provided for @save_draft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get save_draft;

  /// No description provided for @resume_draft.
  ///
  /// In en, this message translates to:
  /// **'Resume Draft'**
  String get resume_draft;

  /// No description provided for @advance_received.
  ///
  /// In en, this message translates to:
  /// **'Advance Received'**
  String get advance_received;

  /// No description provided for @view_receipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get view_receipt;

  /// No description provided for @mark_delivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get mark_delivered;

  /// No description provided for @record_payment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get record_payment;

  /// No description provided for @outstanding_balance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstanding_balance;

  /// No description provided for @call_customer.
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get call_customer;

  /// No description provided for @search_customers.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone'**
  String get search_customers;

  /// No description provided for @new_order_for_customer.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get new_order_for_customer;

  /// No description provided for @customer_summary.
  ///
  /// In en, this message translates to:
  /// **'Customer Summary'**
  String get customer_summary;

  /// No description provided for @new_order_with_customer.
  ///
  /// In en, this message translates to:
  /// **'New Order with Customer'**
  String get new_order_with_customer;

  /// No description provided for @reuse_last_measurements.
  ///
  /// In en, this message translates to:
  /// **'Use Last Measurements'**
  String get reuse_last_measurements;

  /// No description provided for @no_measurements.
  ///
  /// In en, this message translates to:
  /// **'No measurements saved'**
  String get no_measurements;

  /// No description provided for @deliver_today.
  ///
  /// In en, this message translates to:
  /// **'Deliver Today'**
  String get deliver_today;

  /// No description provided for @ready_for_pickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get ready_for_pickup;

  /// No description provided for @deliver_order.
  ///
  /// In en, this message translates to:
  /// **'Deliver Order'**
  String get deliver_order;

  /// No description provided for @balance_due_before_delivery.
  ///
  /// In en, this message translates to:
  /// **'Balance Due Before Delivery'**
  String get balance_due_before_delivery;

  /// No description provided for @my_jobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get my_jobs;

  /// No description provided for @assigned_to_me.
  ///
  /// In en, this message translates to:
  /// **'Assigned to Me'**
  String get assigned_to_me;

  /// No description provided for @mark_ready.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready'**
  String get mark_ready;

  /// No description provided for @no_assigned_jobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs assigned currently'**
  String get no_assigned_jobs;
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
