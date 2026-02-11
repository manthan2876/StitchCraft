import 'package:shared_preferences/shared_preferences.dart';

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

  // Trade-specific terminology translations
  final Map<String, Map<String, String>> _translations = {
    // Dashboard & Navigation
    'dashboard': {
      'en': 'Galla & Orders',
      'hi': 'गल्ला और ऑर्डर',
      'gu': 'ગલ્લા અને ઓર્ડર',
      'mr': 'गल्ला आणि ऑर्डर',
    },
    'new_order': {
      'en': 'New Silai',
      'hi': 'नई सिलाई',
      'gu': 'નવી સિલાઈ',
      'mr': 'नवीन शिलाई',
    },
    'customers': {
      'en': 'Customers',
      'hi': 'ग्राहक (Customers)',
      'gu': 'ગ્રાહકો',
      'mr': 'ग्राहक',
    },
    'measurements': {
      'en': 'Measurements (Naap)',
      'hi': 'नाप (Measurements)',
      'gu': 'માપ (Naap)',
      'mr': 'मोजमाप (Naap)',
    },
    
    // Tailoring Terms
    'stitching': {
      'en': 'Stitching',
      'hi': 'सिलाई',
      'gu': 'સિલાઈ',
      'mr': 'शिवणकाम',
    },
    'cutting': {
      'en': 'Cutting',
      'hi': 'कटाई',
      'gu': 'કટીંગ',
      'mr': 'कापणी',
    },
    'fitting': {
      'en': 'Fitting',
      'hi': 'फिटिंग',
      'gu': 'ફિટિંગ',
      'mr': 'फिटिंग',
    },
    'astar': {
      'en': 'Lining',
      'hi': 'अस्तर',
      'gu': 'અસ્તર',
      'mr': 'अस्तर',
    },
    'fall_pico': {
      'en': 'Fall-Pico',
      'hi': 'फॉल-पिको',
      'gu': 'ફોલ-પિકો',
      'mr': 'फॉल-पिको',
    },
    'turpai': {
      'en': 'Hemming',
      'hi': 'तुरपाई',
      'gu': 'તુરપાઈ',
      'mr': 'तुरपाई',
    },
    'chain_badlai': {
      'en': 'Zipper Replacement',
      'hi': 'चेन बदलाई',
      'gu': 'ચેઈન બદલાઈ',
      'mr': 'चेन बदलाई',
    },
    
    // Financial Terms
    'galla': {
      'en': 'Cash Box',
      'hi': 'गल्ला',
      'gu': 'ગલ્લા',
      'mr': 'गल्ला',
    },
    'udhaar': {
      'en': 'Credit',
      'hi': 'उधार',
      'gu': 'ઉધાર',
      'mr': 'उधार',
    },
    'khata': {
      'en': 'Ledger',
      'hi': 'खाता',
      'gu': 'ખાતા',
      'mr': 'खाता',
    },
    'advance': {
      'en': 'Advance',
      'hi': 'अग्रिम',
      'gu': 'એડવાન્સ',
      'mr': 'आगाऊ',
    },
    'balance': {
      'en': 'Balance',
      'hi': 'बाकी',
      'gu': 'બાકી',
      'mr': 'शिल्लक',
    },
    
    // Garment Types
    'blouse': {
      'en': 'Blouse',
      'hi': 'ब्लाउज',
      'gu': 'બ્લાઉઝ',
      'mr': 'ब्लाउज',
    },
    'choli': {
      'en': 'Choli',
      'hi': 'चोली',
      'gu': 'ચોળી',
      'mr': 'चोळी',
    },
    'kurta': {
      'en': 'Kurta',
      'hi': 'कुर्ता',
      'gu': 'કુર્તા',
      'mr': 'कुर्ता',
    },
    'salwar': {
      'en': 'Salwar',
      'hi': 'सलवार',
      'gu': 'સલવાર',
      'mr': 'सलवार',
    },
    'lehenga': {
      'en': 'Lehenga',
      'hi': 'लहंगा',
      'gu': 'લહેંગા',
      'mr': 'लहंगा',
    },
    
    // Measurement Terms
    'chest': {
      'en': 'Chest',
      'hi': 'छाती',
      'gu': 'છાતી',
      'mr': 'छाती',
    },
    'waist': {
      'en': 'Waist',
      'hi': 'कमर',
      'gu': 'કમર',
      'mr': 'कंबर',
    },
    'hip': {
      'en': 'Hip',
      'hi': 'कूल्हा',
      'gu': 'હિપ',
      'mr': 'नितंब',
    },
    'length': {
      'en': 'Length',
      'hi': 'लंबाई',
      'gu': 'લંબાઈ',
      'mr': 'लांबी',
    },
    'shoulder': {
      'en': 'Shoulder',
      'hi': 'कंधा',
      'gu': 'ખભા',
      'mr': 'खांदा',
    },
    'sleeve': {
      'en': 'Sleeve',
      'hi': 'आस्तीन',
      'gu': 'સ્લીવ',
      'mr': 'बाही',
    },
    
    // Status Terms
    'pending': {
      'en': 'Pending',
      'hi': 'लंबित',
      'gu': 'બાકી',
      'mr': 'प्रलंबित',
    },
    'in_progress': {
      'en': 'In Progress',
      'hi': 'प्रगति में',
      'gu': 'પ્રગતિમાં',
      'mr': 'प्रगतीपथावर',
    },
    'ready': {
      'en': 'Ready',
      'hi': 'तैयार',
      'gu': 'તૈયાર',
      'mr': 'तयार',
    },
    'delivered': {
      'en': 'Delivered',
      'hi': 'डिलीवर',
      'gu': 'ડિલિવર',
      'mr': 'वितरित',
    },
    
    // Actions
    'add': {
      'en': 'Add',
      'hi': 'जोड़ें',
      'gu': 'ઉમેરો',
      'mr': 'जोडा',
    },
    'edit': {
      'en': 'Edit',
      'hi': 'संपादित करें',
      'gu': 'સંપાદિત કરો',
      'mr': 'संपादित करा',
    },
    'delete': {
      'en': 'Delete',
      'hi': 'हटाएं',
      'gu': 'કાઢી નાખો',
      'mr': 'हटवा',
    },
    'save': {
      'en': 'Save',
      'hi': 'सहेजें',
      'gu': 'સાચવો',
      'mr': 'जतन करा',
    },
    'cancel': {
      'en': 'Cancel',
      'hi': 'रद्द करें',
      'gu': 'રદ કરો',
      'mr': 'रद्द करा',
    },
    
    // Common Phrases
    'due_date': {
      'en': 'Due Date',
      'hi': 'नियत तारीख',
      'gu': 'નિયત તારીખ',
      'mr': 'देय तारीख',
    },
    'total_amount': {
      'en': 'Total Amount',
      'hi': 'कुल राशि',
      'gu': 'કુલ રકમ',
      'mr': 'एकूण रक्कम',
    },
    'customer_name': {
      'en': 'Customer Name',
      'hi': 'ग्राहक का नाम',
      'gu': 'ગ્રાહકનું નામ',
      'mr': 'ग्राहकाचे नाव',
    },
    'phone_number': {
      'en': 'Phone Number',
      'hi': 'फोन नंबर',
      'gu': 'ફોન નંબર',
      'mr': 'फोन नंबर',
    },
    
    // Antigravity UI Terms
    'measurement_fit': {
      'en': 'Fit Type',
      'hi': 'फिटिंग कैसी चाहिए?',
      'gu': 'ફિટિંગ કેવી જોઈએ?',
      'mr': 'फिटिंग कशी पाहिजे?',
    },
    'tight': {
      'en': 'Skin Tight',
      'hi': 'चिपक के (Tight)',
      'gu': 'એકદમ ફિટ',
      'mr': 'घट्ट (Tight)',
    },
    'loose': {
      'en': 'Comfortable',
      'hi': 'खुला-खुला (Loose)',
      'gu': 'ઢીલું',
      'mr': 'सैल (Loose)',
    },
  };

  String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
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
