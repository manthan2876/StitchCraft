import 'package:shared_preferences/shared_preferences.dart';
import '../config/translations_data.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLanguage = 'en'; // en, hi, gu, mr

  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  String translate(String key) {
    return translations[key]?[_currentLanguage] ?? key;
  }

  String t(String key) => translate(key);

  // Get language name
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'gu':
        return 'ગુજરાતી';
      case 'mr':
        return 'मराठी';
      default:
        return code;
    }
  }

  List<String> get supportedLanguages => ['en', 'hi', 'gu', 'mr'];
}
