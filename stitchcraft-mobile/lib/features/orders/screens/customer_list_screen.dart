import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/device_contacts_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:http/http.dart' as http;
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class CustomerListScreen extends StatefulWidget {
  final bool isTab;
  const CustomerListScreen({super.key, this.isTab = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> get _displayCustomers {
    if (_searchQuery.trim().isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      var list = await _localDb.getRecords('customers');

      // Fallback: If local database is empty, fetch from remote API to populate
      if (list.isEmpty) {
        final token = await AuthService().getToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse('${AuthService.baseUrl}/customers'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode == 200) {
            final List<dynamic> remoteData = json.decode(response.body);
            for (final rawRecord in remoteData) {
              final Map<String, dynamic> remoteRecord =
                  Map<String, dynamic>.from(rawRecord);
              final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
              if (id.isEmpty) continue;

              final Map<String, dynamic> sqliteRecord = {
                'id': id,
                'name': remoteRecord['name'] ?? 'Unknown',
                'phone': remoteRecord['phone'] ?? '',
                'email': remoteRecord['email'] ?? '',
                'sync_status': 0,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              };
              await _localDb.insertRecord('customers', sqliteRecord);
            }
            list = await _localDb.getRecords('customers');
          }
        }
      }

      final seenPhones = <String>{};
      final uniqueCustomers = <Map<String, dynamic>>[];
      for (final c in list) {
        final phone = PhoneUtils.sanitizePhoneNumber((c['phone'] ?? '').toString());
        if (phone.isNotEmpty) {
          if (seenPhones.add(phone)) {
            uniqueCustomers.add(c);
          }
        } else {
          uniqueCustomers.add(c);
        }
      }

      setState(() {
        _customers = uniqueCustomers;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool saveToDeviceContacts = true;
    bool isContactAlreadySaved = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ctx.loc.add_customer,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandPurple,
                          side: const BorderSide(
                            color: AppTheme.brandPurple,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.contacts_outlined, size: 20),
                        label: Text(
                          ctx.loc.import_contacts,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () async {
                          final picked = await DeviceContactsService()
                              .pickContact(ctx);
                          if (picked != null) {
                            setSheetState(() {
                              nameController.text = picked.fullName;
                              phoneController.text = picked.phoneNumber;
                              isContactAlreadySaved = picked.phoneNumber.isNotEmpty;
                              saveToDeviceContacts = picked.phoneNumber.isEmpty;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: (_) {
                        if (isContactAlreadySaved) {
                          setSheetState(() => isContactAlreadySaved = false);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Customer Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: (_) {
                        if (isContactAlreadySaved) {
                          setSheetState(() => isContactAlreadySaved = false);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NeoCard(
                      child: CheckboxListTile(
                        value: saveToDeviceContacts,
                        onChanged: isContactAlreadySaved
                            ? null
                            : (val) => setSheetState(
                                () => saveToDeviceContacts = val ?? false,
                              ),
                        title: Text(
                          ctx.loc.save_contact_to_phone,
                          style: TextStyle(
                            color: isContactAlreadySaved
                                ? AppTheme.darkGrey
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: isContactAlreadySaved
                            ? Text(
                                ctx.loc.already_in_contacts,
                                style: const TextStyle(
                                  color: AppTheme.trustGreen,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.brandPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: isSubmitting ? 'Saving...' : ctx.loc.add_customer,
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final email = emailController.text.trim();

                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter customer name and phone number',
                              ),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                          return;
                        }

                        setSheetState(() => isSubmitting = true);
                        try {
                          String customerId = const Uuid().v4();
                          final token = await AuthService().getToken();

                          if (token != null) {
                            try {
                              final response = await http.post(
                                Uri.parse('${AuthService.baseUrl}/customers'),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $token',
                                },
                                body: json.encode({
                                  'name': name,
                                  'phone': phone,
                                  'email': email,
                                }),
                              );
                              if (response.statusCode == 200 ||
                                  response.statusCode == 201) {
                                final remoteData = json.decode(response.body);
                                customerId =
                                    remoteData['_id'] ??
                                    remoteData['id'] ??
                                    customerId;
                              }
                            } catch (apiErr) {
                              debugPrint(
                                'Error syncing customer with server: $apiErr',
                              );
                            }
                          }

                          // Save or update in local database
                          final existingList = await _localDb.getRecords('customers');
                          final cleanPhone = PhoneUtils.sanitizePhoneNumber(phone);
                          final existing = existingList.firstWhere(
                            (c) => PhoneUtils.sanitizePhoneNumber(c['phone']?.toString() ?? '') == cleanPhone,
                            orElse: () => {},
                          );
                          if (existing.isNotEmpty && existing['id'] != null) {
                            customerId = existing['id'].toString();
                            await _localDb.updateRecord('customers', customerId, {
                              'name': name,
                              'email': email,
                              'updated_at': DateTime.now().millisecondsSinceEpoch,
                            });
                          } else {
                            await _localDb.insertRecord('customers', {
                              'id': customerId,
                              'name': name,
                              'phone': phone,
                              'email': email,
                              'sync_status': 0,
                              'updated_at': DateTime.now().millisecondsSinceEpoch,
                            });
                          }

                          // Automatically save to mobile phone directory if selected
                          if (saveToDeviceContacts) {
                            DeviceContactsService().saveContactToPhone(
                              fullName: name,
                              phoneNumber: phone,
                              email: email,
                            );
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.loc.customer_added_successfully,
                                ),
                                backgroundColor: AppTheme.trustGreen,
                              ),
                            );
                          }
                          _loadCustomers();
                        } catch (e) {
                          debugPrint('Error creating customer: $e');
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add customer: $e'),
                                backgroundColor: AppTheme.alertRed,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setSheetState(() => isSubmitting = false);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _displayCustomers;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.loc.customers),
        actions: [
          IconButton(
            tooltip: context.loc.add_customer,
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddCustomerBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayed.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? context.loc.no_customers_found
                              : 'No customers match "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, widget.isTab ? 96 : 24),
                        itemCount: displayed.length,
                        itemBuilder: (context, index) {
                          final customer = displayed[index];
                          final String name = customer['name'] ?? 'Walk-in Customer';
                          final String phone = (customer['phone'] ?? '').toString();
                          final String email = (customer['email'] ?? '').toString();

                          final String subtitleText = email.isNotEmpty
                              ? (phone.isNotEmpty ? '$phone • $email' : email)
                              : phone;

                          return NeoCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/customer_details',
                                  arguments: customer['_id'] ?? customer['id'] ?? '',
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.brandPurple.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    color: AppTheme.brandPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: subtitleText.isNotEmpty
                                  ? Text(
                                      subtitleText,
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (phone.isNotEmpty) ...[
                                    IconButton(
                                      icon: const Icon(Icons.phone_outlined, size: 20),
                                      color: AppTheme.brandPurple,
                                      tooltip: 'Call $name',
                                      onPressed: () async {
                                        final uri = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat_outlined, size: 20),
                                      color: const Color(0xFF25D366),
                                      tooltip: 'WhatsApp $name',
                                      onPressed: () async {
                                        final clean = phone.replaceAll(RegExp(r'\D'), '');
                                        final target = clean.startsWith('91') || clean.length != 10 ? clean : '91$clean';
                                        final uri = Uri.parse('https://wa.me/$target');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  ],
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppTheme.darkGrey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.isTab
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.brandPurple,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                context.loc.add_customer,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showAddCustomerBottomSheet(context),
            ),
    );
  }
}
