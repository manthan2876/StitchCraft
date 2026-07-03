import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/localization/generated/app_localizations.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en', ''));

  String get currentLanguage => localeNotifier.value.languageCode;

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String code = prefs.getString('language') ?? 'en';
    localeNotifier.value = Locale(code, '');
  }

  Future<void> setLanguage(String languageCode) async {
    localeNotifier.value = Locale(languageCode, '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  String translate(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    if (l == null) return key;
    switch (key) {
      case 'dashboard_title': return l.dashboard_title;
      case 'cash_reserve': return l.cash_reserve;
      case 'pending_orders': return l.pending_orders;
      case 'weekly_output': return l.weekly_output;
      case 'performance_summary': return l.performance_summary;
      case 'new_order': return l.new_order;
      case 'khata_ledger': return l.khata_ledger;
      case 'inventory_stock': return l.inventory_stock;
      case 'tailoring_staff': return l.tailoring_staff;
      case 'repair_jobs': return l.repair_jobs;
      case 'measurements': return l.measurements;
      case 'home_dashboard': return l.home_dashboard;
      case 'orders': return l.orders;
      case 'customers': return l.customers;
      case 'billing_dispatch': return l.billing_dispatch;
      case 'deliveries': return l.deliveries;
      case 'invoices': return l.invoices;
      case 'payments': return l.payments;
      case 'karigars': return l.karigars;
      case 'machines': return l.machines;
      case 'change_language': return l.change_language;
      case 'shop_settings': return l.shop_settings;
      case 'logout': return l.logout;
      case 'save': return l.save;
      case 'add': return l.add;
      case 'cancel': return l.cancel;
      default: return key;
    }
  }

  String t(BuildContext context, String key) => translate(context, key);

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return code;
    }
  }

  List<String> get supportedLanguages => ['en', 'hi', 'gu'];
}
