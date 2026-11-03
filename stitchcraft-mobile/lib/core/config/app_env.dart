import 'package:flutter/foundation.dart';

class AppEnv {
  static const String backendApiUrl = String.fromEnvironment('BACKEND_API_URL');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static void validate() {
    validateValues(
      backendUrl: backendApiUrl,
      supabaseProjectUrl: supabaseUrl,
      supabaseKey: supabaseAnonKey,
      isRelease: kReleaseMode,
    );
  }

  @visibleForTesting
  static void validateValues({
    required String backendUrl,
    required String supabaseProjectUrl,
    required String supabaseKey,
    required bool isRelease,
  }) {
    if (backendUrl.trim().isEmpty) {
      throw StateError(
        'Missing BACKEND_API_URL. Provide it via --dart-define-from-file=env/dev.json',
      );
    }
    final backendUri = Uri.tryParse(backendUrl.trim());
    if (backendUri == null ||
        backendUri.host.isEmpty ||
        !{'http', 'https'}.contains(backendUri.scheme)) {
      throw StateError('BACKEND_API_URL must be an absolute HTTP(S) URL');
    }
    if (isRelease && backendUri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS BACKEND_API_URL');
    }
    if (supabaseProjectUrl.trim().isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL. Provide it via --dart-define-from-file=env/dev.json',
      );
    }
    final supabaseUri = Uri.tryParse(supabaseProjectUrl.trim());
    if (supabaseUri == null ||
        supabaseUri.host.isEmpty ||
        supabaseUri.scheme != 'https') {
      throw StateError('SUPABASE_URL must be an absolute HTTPS URL');
    }
    if (supabaseKey.trim().isEmpty) {
      throw StateError(
        'Missing SUPABASE_ANON_KEY. Provide it via --dart-define-from-file=env/dev.json',
      );
    }
  }
}
