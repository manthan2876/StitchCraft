import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
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

  /// Picks a contact by requesting runtime permission and opening the native contact picker.
  /// If the external picker fails on OEM devices, gracefully falls back to an in-app searchable contact picker.
  Future<PickedContactResult?> pickContact(BuildContext context) async {
    try {
      // 1. Ensure runtime READ_CONTACTS permission is granted
      final permissionStatus = await FlutterContacts.permissions.request(PermissionType.read);
      final hasPermission = permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited;
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required to select from contacts.'),
              backgroundColor: AppTheme.alertRed,
            ),
          );
        }
        return null;
      }

      // 2. Open external system contact picker
      Contact? contact;
      try {
        contact = await FlutterContacts.native.showPicker(
          properties: ContactProperties.allProperties,
        );
      } catch (e) {
        debugPrint('showPicker failed, falling back to in-app picker: $e');
        if (context.mounted) {
          return await _showInAppContactPicker(context);
        }
        return null;
      }

      // User cancelled picker
      if (contact == null) return null;

      // 3. Retrieve full properties if external pick returned a lightweight shell
      Contact fullContact = contact;
      if (fullContact.phones.isEmpty && contact.id != null) {
        try {
          final fetched = await FlutterContacts.get(
            contact.id!,
            properties: ContactProperties.allProperties,
          );
          if (fetched != null) {
            fullContact = fetched;
          }
        } catch (e) {
          debugPrint('Error getting full contact by ID: $e');
        }
      }

      final phones = fullContact.phones;
      String name = fullContact.displayName?.trim() ?? '';
      if (name.isEmpty) {
        final first = fullContact.name?.first ?? '';
        final last = fullContact.name?.last ?? '';
        name = '$first $last'.trim();
      }
      if (name.isEmpty && phones.isNotEmpty) {
        name = phones.first.number;
      }

      if (phones.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected contact does not have a phone number.'),
              backgroundColor: AppTheme.warmAmber,
            ),
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
      final selectedPhone = await _showPhoneNumberSelector(context, name, phones);
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

  /// Phone number selection modal for contacts with multiple numbers
  Future<String?> _showPhoneNumberSelector(
    BuildContext context,
    String name,
    List<Phone> phones,
  ) async {
    final theme = Theme.of(context);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Phone Number',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...phones.map((p) {
                final labelText = p.label.label == PhoneLabel.custom
                    ? ((p.label.customLabel != null && p.label.customLabel!.isNotEmpty)
                        ? p.label.customLabel!
                        : 'Custom')
                    : p.label.label.name;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: AppTheme.brandPurple, size: 20),
                  ),
                  title: Text(
                    p.number,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    labelText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.pop(ctx, p.number),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// In-app searchable contact picker bottom sheet fallback
  Future<PickedContactResult?> _showInAppContactPicker(BuildContext context) async {
    try {
      final contacts = await FlutterContacts.getAll(
        properties: ContactProperties.allProperties,
      );

      if (!context.mounted) return null;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found on device.')),
        );
        return null;
      }

      final validContacts = contacts.where((c) {
        final dName = c.displayName?.trim() ?? '';
        final fName = c.name?.first?.trim() ?? '';
        final lName = c.name?.last?.trim() ?? '';
        return dName.isNotEmpty || fName.isNotEmpty || lName.isNotEmpty || c.phones.isNotEmpty;
      }).toList();

      return await showModalBottomSheet<PickedContactResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _InAppContactPickerSheet(contacts: validContacts),
      );
    } catch (e) {
      debugPrint('Error loading in-app contacts: $e');
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
      final permissionStatus = await FlutterContacts.permissions.request(PermissionType.readWrite);
      final hasPermission = permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited;
      if (!hasPermission) {
        debugPrint('Contact write permission was denied by user.');
        return false;
      }

      // 2. Split into First Name and Last Name
      final nameParts = trimmedName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // 3. Construct Contact object
      final newContact = Contact(
        name: Name(
          first: firstName,
          last: lastName,
        ),
        phones: [
          Phone(
            number: cleanedPhone,
            label: const Label(PhoneLabel.mobile),
          ),
        ],
        emails: (email != null && email.trim().isNotEmpty)
            ? [
                Email(
                  address: email.trim(),
                  label: const Label(EmailLabel.home),
                ),
              ]
            : const [],
      );

      // 4. Save into native contact book
      await FlutterContacts.create(newContact);
      debugPrint('Successfully saved contact to mobile phone directory: $trimmedName ($cleanedPhone)');
      return true;
    } catch (e) {
      debugPrint('Failed to save contact to phone: $e');
      return false;
    }
  }
}

class _InAppContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _InAppContactPickerSheet({required this.contacts});

  @override
  State<_InAppContactPickerSheet> createState() => _InAppContactPickerSheetState();
}

class _InAppContactPickerSheetState extends State<_InAppContactPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<Contact> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.contacts;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.contacts;
      } else {
        _filtered = widget.contacts.where((c) {
          final displayName = c.displayName?.trim() ?? '';
          final fullName = displayName.isNotEmpty
              ? displayName
              : '${c.name?.first ?? ''} ${c.name?.last ?? ''}'.trim();
          final name = fullName.toLowerCase();
          final phoneMatches = c.phones.any((p) => p.number.replaceAll(RegExp(r'\s+'), '').contains(query));
          return name.contains(query) || phoneMatches;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Contact',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching contacts',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, index) {
                      final c = _filtered[index];
                      final displayName = c.displayName?.trim() ?? '';
                      final resolvedName = displayName.isNotEmpty
                          ? displayName
                          : '${c.name?.first ?? ''} ${c.name?.last ?? ''}'.trim();
                      final hasPhones = c.phones.isNotEmpty;
                      final primaryPhone = hasPhones ? c.phones.first.number : 'No phone number';
                      final name = resolvedName.isNotEmpty ? resolvedName : primaryPhone;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppTheme.brandPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          primaryPhone,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          if (c.phones.isEmpty) {
                            Navigator.pop(
                              context,
                              PickedContactResult(
                                fullName: name,
                                phoneNumber: '',
                              ),
                            );
                          } else if (c.phones.length == 1) {
                            Navigator.pop(
                              context,
                              PickedContactResult(
                                fullName: name,
                                phoneNumber: PhoneUtils.sanitizePhoneNumber(c.phones.first.number),
                              ),
                            );
                          } else {
                            _showPhoneOptions(context, name, c.phones);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPhoneOptions(BuildContext context, String name, List<Phone> phones) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choose number for $name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ...phones.map((p) => ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(p.number),
                  subtitle: Text(p.label.label.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                  onTap: () => Navigator.pop(ctx, p.number),
                )),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      Navigator.pop(
        context,
        PickedContactResult(
          fullName: name,
          phoneNumber: PhoneUtils.sanitizePhoneNumber(selected),
        ),
      );
    }
  }
}
