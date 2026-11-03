import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:stitchcraft/core/config/app_env.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppTheme Unit Tests', () {
    test('Primary theme color (Deep Bronze) should be correct', () {
      expect(AppTheme.deepBronze, const Color(0xFF765220));
    });

    test('Success color (Trust Green) should be correct', () {
      expect(AppTheme.trustGreen, const Color(0xFF2E7D32));
    });

    test('Theme should map navyBlue to deepBronze correctly', () {
      expect(AppTheme.navyBlue, AppTheme.deepBronze);
    });

    test('Soft White background color check', () {
      expect(AppTheme.softWhite, const Color(0xFFFAFAFA));
    });
  });

  group('PhoneUtils Unit Tests', () {
    test('Sanitizes simple 10 digit number', () {
      expect(PhoneUtils.sanitizePhoneNumber('9876543210'), '9876543210');
    });

    test('Sanitizes spaces and dashes', () {
      expect(PhoneUtils.sanitizePhoneNumber('98765 43210'), '9876543210');
      expect(PhoneUtils.sanitizePhoneNumber('98765-43210'), '9876543210');
      expect(PhoneUtils.sanitizePhoneNumber('(987) 654-3210'), '9876543210');
    });

    test('Sanitizes Indian +91 and 0 prefix', () {
      expect(PhoneUtils.sanitizePhoneNumber('+91 98765 43210'), '9876543210');
      expect(PhoneUtils.sanitizePhoneNumber('+919876543210'), '9876543210');
      expect(PhoneUtils.sanitizePhoneNumber('09876543210'), '9876543210');
    });

    test('Handles empty phone number gracefully', () {
      expect(PhoneUtils.sanitizePhoneNumber(''), '');
    });
  });

  group('AppEnv Security & Config Tests', () {
    test('Enforces environment variable validation', () {
      if (AppEnv.supabaseUrl.isEmpty || AppEnv.backendApiUrl.isEmpty) {
        expect(() => AppEnv.validate(), throwsA(isA<StateError>()));
      } else {
        expect(() => AppEnv.validate(), returnsNormally);
      }
    });

    test('Rejects insecure release backend URLs', () {
      expect(
        () => AppEnv.validateValues(
          backendUrl: 'http://api.example.com',
          supabaseProjectUrl: 'https://project.supabase.co',
          supabaseKey: 'anon-key',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Accepts development HTTP backend URLs', () {
      expect(
        () => AppEnv.validateValues(
          backendUrl: 'http://10.0.2.2:5000/api',
          supabaseProjectUrl: 'https://project.supabase.co',
          supabaseKey: 'anon-key',
          isRelease: false,
        ),
        returnsNormally,
      );
    });

    test('Rejects non-HTTPS Supabase URLs', () {
      expect(
        () => AppEnv.validateValues(
          backendUrl: 'https://api.example.com',
          supabaseProjectUrl: 'http://project.example.com',
          supabaseKey: 'anon-key',
          isRelease: false,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
