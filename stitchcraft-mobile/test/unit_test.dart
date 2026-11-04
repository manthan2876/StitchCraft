import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/models/user_model.dart';
import 'package:stitchcraft/core/services/whatsapp_service.dart';
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

  group('CurrencyUtils Unit Tests', () {
    test('Formats standard INR with paise', () {
      expect(CurrencyUtils.formatINR(500), '₹500.00');
      expect(CurrencyUtils.formatINR(1250), '₹1,250.00');
    });

    test('Formats Indian lakh and crore number groupings correctly', () {
      expect(CurrencyUtils.formatINR(100000), '₹1,00,000.00');
      expect(CurrencyUtils.formatINR(1234567.50), '₹12,34,567.50');
      expect(CurrencyUtils.formatINR(10000000), '₹1,00,00,000.00');
    });

    test('Formats without decimals when showDecimals is false', () {
      expect(CurrencyUtils.formatINR(500, showDecimals: false), '₹500');
      expect(CurrencyUtils.formatINR(125000, showDecimals: false), '₹1,25,000');
    });

    test('Handles null and zero values safely', () {
      expect(CurrencyUtils.formatINR(null), '₹0.00');
      expect(CurrencyUtils.formatINR(0), '₹0.00');
    });

    test('Calculates balance accurately without negative results', () {
      expect(CurrencyUtils.calculateBalance(totalAmount: 1000, paidAmount: 400), 600.0);
      expect(CurrencyUtils.calculateBalance(totalAmount: 1000, paidAmount: 1000), 0.0);
      expect(CurrencyUtils.calculateBalance(totalAmount: 1000, paidAmount: 1200), 0.0);
    });
  });

  group('UserRole & Permission Gate Unit Tests', () {
    test('Role parsing from string handles variations and aliases', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('Owner'), UserRole.owner);
      expect(UserRole.fromString('manager'), UserRole.owner);
      expect(UserRole.fromString('karigar'), UserRole.owner);
      expect(UserRole.fromString('staff'), UserRole.owner);
      expect(UserRole.fromString('unknown_role'), UserRole.owner);
      expect(UserRole.fromString(null), UserRole.owner);
    });

    test('Owner has full shop, staff, deletion, and financial capabilities', () {
      const role = UserRole.owner;
      expect(role.isOwner, true);
      expect(role.isAdmin, false);
      expect(role.canManageShop, true);
      expect(role.canDeleteShop, true);
      expect(role.canManageStaff, true);
      expect(role.canDeleteOrders, true);
      expect(role.canViewFinancials, true);
    });

    test('Admin role has administrative and management access', () {
      const role = UserRole.admin;
      expect(role.isAdmin, true);
      expect(role.isOwner, false);
      expect(role.canManageShop, true);
      expect(role.canManageStaff, true);
      expect(role.canDeleteOrders, true);
      expect(role.canViewFinancials, true);
    });

    test('Legacy roles map cleanly to owner on mobile', () {
      expect(UserRole.manager, UserRole.owner);
      expect(UserRole.staff, UserRole.owner);
      expect(UserRole.karigar, UserRole.owner);
    });
  });

  group('WhatsAppService Message Formatting Tests', () {
    test('Generates canonical stage notifications for workshop lifecycle', () {
      final incoming = WhatsAppService.buildOrderUpdateMessage('ORD-101', 'Incoming');
      expect(incoming.contains('#ORD-101'), true);
      expect(incoming.contains('received and booked'), true);

      final stitching = WhatsAppService.buildOrderUpdateMessage('ORD-101', 'Stitching');
      expect(stitching.contains('#ORD-101'), true);
      expect(stitching.contains('handcrafted in our workshop'), true);

      final ready = WhatsAppService.buildOrderUpdateMessage('ORD-101', 'Ready');
      expect(ready.contains('#ORD-101'), true);
      expect(ready.contains('ready for trial / pickup'), true);

      final delivered = WhatsAppService.buildOrderUpdateMessage('ORD-101', 'Delivered');
      expect(delivered.contains('#ORD-101'), true);
      expect(delivered.contains('delivered'), true);
    });

    test('Generates gentle Udhar payment reminder message with formatted balance', () {
      final reminder = WhatsAppService.buildPaymentReminderMessage(
        customerName: 'Anil Kumar',
        orderId: 'ORD-202',
        balanceAmount: 1500,
      );
      expect(reminder.contains('Anil Kumar'), true);
      expect(reminder.contains('Order #ORD-202'), true);
      expect(reminder.contains('₹1,500.00'), true);
    });
  });

  group('UX & Design System Tokens (DS-01 & DS-02)', () {
    test('Enforces counter-first touch target dimensions', () {
      expect(AppTheme.minTouchTarget, 48.0);
      expect(AppTheme.primaryButtonHeight, 56.0);
      expect(AppTheme.standardPadding, 16.0);
    });

    test('Semantic color tokens are properly defined', () {
      expect(AppTheme.primaryAction, AppTheme.brandPurple);
      expect(AppTheme.success, AppTheme.trustGreen);
      expect(AppTheme.warning, AppTheme.safetyOrange);
      expect(AppTheme.danger, AppTheme.alertRed);
      expect(AppTheme.pending, const Color(0xFF0284C7));
    });
  });
}
