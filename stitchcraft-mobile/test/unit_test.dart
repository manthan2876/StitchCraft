import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
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
}
