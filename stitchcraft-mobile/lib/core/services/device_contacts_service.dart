import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';

class PickedContactResult {
  final String fullName;
  final String phoneNumber;

  PickedContactResult({required this.fullName, required this.phoneNumber});
}
class DeviceContactsService {
  static final DeviceContactsService _instance = DeviceContactsService._internal();
  factory DeviceContactsService() => _instance;
  DeviceContactsService._internal();

  /// Approach A: Opens native system contact picker directly.
  /// Does not require dangerous runtime READ_CONTACTS permission.
  Future<PickedContactResult?> pickContact(BuildContext context) async {
    try {
      final Contact? contact = await FlutterContacts.openExternalPick();
      if (contact == null) return null; // User cancelled picker

      // Retrieve full properties in case external pick returned a lightweight shell
      Contact? fullContact = contact;
      if (fullContact.phones.isEmpty) {
        fullContact = await FlutterContacts.getContact(contact.id) ?? contact;
      }

      final String name = fullContact.displayName.isNotEmpty
          ? fullContact.displayName.trim()
          : '${fullContact.name.first} ${fullContact.name.last}'.trim();

      final phones = fullContact.phones;

      if (phones.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected contact has no phone number.')),
          );
        }
        return PickedContactResult(
          fullName: name,
          phoneNumber: '',
        );
      }

      if (phones.length == 1) {
        return PickedContactResult(
          fullName: name,
          phoneNumber: PhoneUtils.sanitizePhoneNumber(phones.first.number),
        );
      }

      // If contact has multiple phone numbers, prompt user to select one
      if (!context.mounted) return null;
      final theme = Theme.of(context);

      final selectedPhone = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Phone Number',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...phones.map((p) {
                final labelText = p.label == PhoneLabel.custom ? (p.customLabel) : p.label.name;
                return ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(p.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(labelText.toUpperCase(), style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.check, size: 18),
                  onTap: () => Navigator.pop(ctx, p.number),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (selectedPhone == null) return null;

      return PickedContactResult(
        fullName: name,
        phoneNumber: PhoneUtils.sanitizePhoneNumber(selectedPhone),
      );
    } catch (e) {
      debugPrint('Error picking contact: $e');
      return null;
    }
  }

  /// Automatically creates and saves a new contact directly into the device's native address book.
  Future<bool> saveContactToPhone({
    required String fullName,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final cleanedPhone = PhoneUtils.sanitizePhoneNumber(phoneNumber);
      final trimmedName = fullName.trim();
      if (trimmedName.isEmpty || cleanedPhone.isEmpty) return false;

      // 1. Request contact write permission
      final hasPermission = await FlutterContacts.requestPermission(readonly: false);
      if (!hasPermission) {
        debugPrint('Contact write permission was denied by user.');
        return false;
      }

      // 2. Split into First Name and Last Name
      final nameParts = trimmedName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // 3. Construct Contact object
      final newContact = Contact()
        ..name.first = firstName
        ..name.last = lastName
        ..phones = [Phone(cleanedPhone, label: PhoneLabel.mobile)];

      if (email != null && email.trim().isNotEmpty) {
        newContact.emails = [Email(email.trim(), label: EmailLabel.home)];
      }

      // 4. Save into native contact book
      await newContact.insert();
      debugPrint('Successfully saved contact to mobile phone directory: $trimmedName ($cleanedPhone)');
      return true;
    } catch (e) {
      debugPrint('Failed to save contact to phone: $e');
      return false;
    }
  }
}
