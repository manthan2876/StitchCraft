import 'package:stitchcraft/core/config/app_env.dart';

class ApiConfig {
  static String get baseUrl {
    final value = AppEnv.backendApiUrl.trim();
    if (value.isEmpty) {
      throw StateError(
        'Missing BACKEND_API_URL. Provide it via --dart-define-from-file=env/dev.json',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
