import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Opens WhatsApp with the specified phone number and message.
  /// Returns `true` if launched successfully, `false` otherwise.
  Future<bool> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      final sanitized = PhoneUtils.sanitizePhoneNumber(phoneNumber);
      if (sanitized.isEmpty || sanitized.length < 10) {
        developer.log('Invalid phone number for WhatsApp: $phoneNumber', name: 'WhatsAppService');
        return false;
      }

      String fullPhone = sanitized;
      if (!fullPhone.startsWith('91') && fullPhone.length == 10) {
        fullPhone = '91$fullPhone';
      }

      final Uri url = Uri.parse(
        'https://wa.me/$fullPhone?text=${Uri.encodeComponent(message ?? '')}',
      );

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        developer.log('Cannot launch WhatsApp URL: $url', name: 'WhatsAppService');
        return false;
      }
    } catch (e) {
      developer.log('Error launching WhatsApp: $e', name: 'WhatsAppService');
      return false;
    }
  }

  /// Builds localized status notification message
  static String buildOrderUpdateMessage(String orderId, String status) {
    switch (status) {
      case 'Incoming':
        return 'Namaste! Your order #$orderId has been received and booked successfully. Thank you for choosing us!';
      case 'Measuring':
        return 'Namaste! Your measurements for order #$orderId have been recorded and sent to our masterji.';
      case 'Cutting':
        return 'Update on order #$orderId: Fabric cutting is currently in progress.';
      case 'Stitching':
        return 'Update on order #$orderId: Your garment is now being handcrafted in our workshop.';
      case 'Checking':
        return 'Update on order #$orderId: Your garment has reached final finishing and quality inspection.';
      case 'Ready':
        return 'Great news! Your order #$orderId is ready for trial / pickup at our store. Please visit us!';
      case 'Delivered':
        return 'Your order #$orderId has been delivered! We hope you love the fit. Please visit us again.';
      default:
        return 'Update on your order #$orderId: Status is now $status.';
    }
  }

  /// Builds gentle payment reminder message
  static String buildPaymentReminderMessage({
    required String customerName,
    required String orderId,
    required double balanceAmount,
  }) {
    final formattedBalance = CurrencyUtils.formatINR(balanceAmount);
    return 'Namaste $customerName, this is a gentle reminder regarding your pending tailoring balance of $formattedBalance for Order #$orderId. Kindly settle at your convenience. Thank you!';
  }

  /// Sends tailored order lifecycle updates using canonical backend stages
  Future<bool> sendOrderUpdate(String phoneNumber, String orderId, String status) async {
    final message = buildOrderUpdateMessage(orderId, status);
    return await openWhatsApp(phoneNumber: phoneNumber, message: message);
  }

  /// Sends friendly payment and Udhar reminders
  Future<bool> sendPaymentReminder({
    required String phoneNumber,
    required String customerName,
    required String orderId,
    required double balanceAmount,
  }) async {
    final message = buildPaymentReminderMessage(
      customerName: customerName,
      orderId: orderId,
      balanceAmount: balanceAmount,
    );
    return await openWhatsApp(phoneNumber: phoneNumber, message: message);
  }
}
