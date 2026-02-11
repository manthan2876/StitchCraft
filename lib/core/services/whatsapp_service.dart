import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  Future<void> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Clean phone number (remove non-digits, ensuring it has country code if possible, or assume local)
      // For now, assuming input might be raw.
      // If starts with +, keep it. If not, maybe append default country code?
      // Let's assume the user enters it correctly or we prepend +91 for India context (StitchCraft context seems Indian with 'Masterji')
      
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }
      
      final Uri url = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message ?? '')}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      developer.log('Error launching WhatsApp: $e', name: 'WhatsAppService');
      // Fallback to SMS or normal dialer?
      // For MVP just log.
    }
  }

  Future<void> sendOrderUpdate(String phoneNumber, String orderId, String status) async {
    String message = '';
    switch (status) {
      case 'Booked':
        message = 'Your order #$orderId has been booked successfully! Thank you for choosing us.';
        break;
      case 'Trial Ready':
        message = 'Good news! Your order #$orderId is ready for trial. Please visit our shop.';
        break;
      case 'Ready':
        message = 'Your order #$orderId is ready for pickup/delivery!';
        break;
      default:
        message = 'Update on your order #$orderId: Status is now $status.';
    }
    await openWhatsApp(phoneNumber: phoneNumber, message: message);
  }
}
