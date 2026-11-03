class PhoneUtils {
  /// Cleans brackets, hyphens, and whitespace, standardizing phone numbers
  static String sanitizePhoneNumber(String raw) {
    if (raw.isEmpty) return '';
    // Strip brackets, hyphens, dots, and whitespace
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Normalize Indian numbers: remove leading +91 or 0 if user enters 10-digit mobile
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }
}
