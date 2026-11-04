import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats amount into Indian currency grouping standard (e.g., ₹1,23,456.00)
  static String formatINR(num? amount, {bool showDecimals = true}) {
    final val = (amount ?? 0).toDouble();
    if (showDecimals) {
      return _inrFormatter.format(val);
    } else {
      return _inrCompactFormatter.format(val);
    }
  }

  /// Calculates authoritative balance
  static double calculateBalance({
    required num totalAmount,
    required num paidAmount,
  }) {
    final balance = totalAmount.toDouble() - paidAmount.toDouble();
    return balance > 0 ? balance : 0.0;
  }
}

