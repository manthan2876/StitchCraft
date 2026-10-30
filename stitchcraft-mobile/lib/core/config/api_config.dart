import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final value = dotenv.env['BACKEND_API_URL']?.trim() ?? '';
    if (value.isEmpty) {
      throw StateError(
        'Missing BACKEND_API_URL. Add it to stitchcraft-mobile/.env.',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
