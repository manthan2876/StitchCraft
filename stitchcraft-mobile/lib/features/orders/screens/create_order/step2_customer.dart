import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/device_contacts_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({super.key});

  @override
  State<CustomerSelectionScreen> createState() =>
      _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _loadError;
  List<dynamic> _customers = [];
  List<dynamic> _filteredCustomers = [];
  final _searchController = TextEditingController();

  Map<String, dynamic>? _wizardData;
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _savedDraft;

  final _newCustNameController = TextEditingController();
  final _newCustPhoneController = TextEditingController();
  bool _isNewCustomer = false;
  bool _saveToDeviceContacts = true;
  bool _isContactAlreadySaved = false;
  final _deviceContactsService = DeviceContactsService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      _wizardData = arguments is Map<String, dynamic>
          ? Map<String, dynamic>.from(arguments)
          : <String, dynamic>{};
      _loadCustomers();
      _checkSavedDraft();
    }
  }

  Future<void> _checkSavedDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftStr = prefs.getString('draft_order_wizard');
      if (draftStr != null && draftStr.isNotEmpty) {
        final decoded = json.decode(draftStr);
        if (decoded is Map<String, dynamic> && mounted) {
          setState(() => _savedDraft = decoded);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final seenPhones = <String>{};
        final uniqueList = <dynamic>[];
        for (final c in data) {
          final phone = PhoneUtils.sanitizePhoneNumber((c['phone'] ?? '').toString());
          if (phone.isNotEmpty) {
            if (seenPhones.add(phone)) {
              uniqueList.add(c);
            }
          } else {
            uniqueList.add(c);
          }
        }
        setState(() {
          _customers = uniqueList;
          _filteredCustomers = uniqueList;
        });
        return;
      } else {
        throw Exception('Unable to load customers (${response.statusCode})');
      }
    } catch (e) {
      developer.log("Remote customers unavailable, checking local DB: $e");
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopId = prefs.getString('shopId');
        final localData = await LocalDatabaseService().getAllCustomers(shopId: shopId);
        final seenPhones = <String>{};
        final uniqueList = <dynamic>[];
        for (final c in localData) {
          final phone = PhoneUtils.sanitizePhoneNumber((c['phone'] ?? '').toString());
          if (phone.isNotEmpty) {
            if (seenPhones.add(phone)) {
              uniqueList.add(c);
            }
          } else {
            uniqueList.add(c);
          }
        }
        if (mounted) {
          setState(() {
            _customers = uniqueList;
            _filteredCustomers = uniqueList;
          });
        }
      } catch (localErr) {
        if (mounted) {
          setState(
            () => _loadError =
                'Could not load customers. Check your connection and try again.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString();
        return name.contains(query.toLowerCase()) || phone.contains(query);
      }).toList();
    });
  }

  Future<void> _pickFromContacts() async {
    final result = await _deviceContactsService.pickContact(context);
    if (result != null && mounted) {
      setState(() {
        _newCustNameController.text = result.fullName;
        _newCustPhoneController.text = result.phoneNumber;
        _isContactAlreadySaved = result.phoneNumber.isNotEmpty;
        _saveToDeviceContacts = result.phoneNumber.isEmpty;
      });
    }
  }

  void _onNext() {
    if (_wizardData == null) return;

    if (_isNewCustomer) {
      final newName = _newCustNameController.text.trim();
      final newPhone = _newCustPhoneController.text.trim();
      if (newName.isEmpty || newPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter name and phone for the new customer'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
        return;
      }

      final cleanPhone = PhoneUtils.sanitizePhoneNumber(newPhone);
      if (cleanPhone.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
        return;
      }

      // Check if duplicate phone exists in loaded customers
      final match = _customers.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c != null && PhoneUtils.sanitizePhoneNumber((c['phone'] ?? '').toString()) == cleanPhone,
        orElse: () => null,
      );

      if (match != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Customer Already Exists'),
            content: Text(
              'A customer named "${match['name']}" is already registered with mobile number $cleanPhone.\n\nWould you like to select "${match['name']}" instead?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isNewCustomer = false;
                    _selectedCustomer = match;
                  });
                },
                child: const Text('Select Existing'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _proceedWithNewCustomer(newName, cleanPhone);
                },
                child: const Text('Continue as New'),
              ),
            ],
          ),
        );
        return;
      }

      _proceedWithNewCustomer(newName, cleanPhone);
    } else {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select an existing customer or toggle to register a new one',
            ),
            backgroundColor: AppTheme.alertRed,
          ),
        );
        return;
      }
      _wizardData!['customer'] = _selectedCustomer;
      _wizardData!.remove('newCustomer');
      Navigator.pushNamed(context, '/create_order_step1', arguments: _wizardData);
    }
  }

  void _proceedWithNewCustomer(String newName, String cleanPhone) {
    _wizardData!['newCustomer'] = {
      'name': newName,
      'phone': cleanPhone,
      'saveToDeviceContacts': _saveToDeviceContacts,
    };
    _wizardData!.remove('customer');
    Navigator.pushNamed(context, '/create_order_step1', arguments: _wizardData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newCustNameController.dispose();
    _newCustPhoneController.dispose();
    super.dispose();
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppTheme.alertRed,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.darkGrey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadCustomers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCustomers() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 52,
              color: AppTheme.brandPurple,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'No customers match your search'
                  : 'No customers yet',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different name or phone number.'
                  : 'Add a customer to start a new order.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.darkGrey),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => setState(() => _isNewCustomer = true),
                child: const Text('Add new customer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('New order · 1 of 5 · Customer')),
      body: Column(
        children: [
          // Draft Resume Banner (UX-04)
          if (_savedDraft != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.pending.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_outlined, color: AppTheme.pending, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unfinished order draft: ${_savedDraft!['garmentType'] ?? 'Garment'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create_order_step5', arguments: _savedDraft);
                    },
                    child: Text(context.loc.resume_draft, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('draft_order_wizard');
                      setState(() => _savedDraft = null);
                    },
                  ),
                ],
              ),
            ),
          ],

          // Segmented button for Existing vs New Customer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isNewCustomer
                          ? AppTheme.brandPurple
                          : theme.cardColor,
                    ),
                    onPressed: () => setState(() => _isNewCustomer = false),
                    child: Text(
                      'Existing Customer',
                      style: TextStyle(
                        color: !_isNewCustomer
                            ? Colors.white
                            : AppTheme.darkGrey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNewCustomer
                          ? AppTheme.brandPurple
                          : theme.cardColor,
                    ),
                    onPressed: () => setState(() => _isNewCustomer = true),
                    child: Text(
                      'New Customer',
                      style: TextStyle(
                        color: _isNewCustomer
                            ? Colors.white
                            : AppTheme.darkGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Walk-in Customer Fast Path
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brandPurple,
                  side: const BorderSide(color: AppTheme.brandPurple),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                label: Text(context.loc.walk_in_customer, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final wizardData = Map<String, dynamic>.from(_wizardData ?? {});
                  wizardData['customer'] = {
                    'id': 'walk_in_${DateTime.now().millisecondsSinceEpoch}',
                    'name': 'Walk-in Customer',
                    'phone': '',
                  };
                  Navigator.pushNamed(
                    context,
                    '/create_order_step1',
                    arguments: wizardData,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: !_isNewCustomer
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterCustomers,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Search Customer...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _loadError != null
                            ? _buildLoadError()
                            : _filteredCustomers.isEmpty
                            ? _buildEmptyCustomers()
                            : ListView.builder(
                                itemCount: _filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final c = _filteredCustomers[index];
                                  final bool isSelected =
                                      _selectedCustomer?['_id'] == c['_id'];

                                  return NeoCard(
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomer = c;
                                      });
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? AppTheme.brandPurple
                                            : AppTheme.darkCard,
                                        child: Icon(
                                          Icons.person,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.brandPurple,
                                        ),
                                      ),
                                      title: Text(
                                        c['name'] ?? 'Guest Customer',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        c['phone'] ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.darkGrey,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.trustGreen,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Register Customer Details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
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
                              context.loc.import_contacts,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: _pickFromContacts,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newCustNameController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onChanged: (_) {
                            if (_isContactAlreadySaved) {
                              setState(() => _isContactAlreadySaved = false);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Customer Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newCustPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onChanged: (_) {
                            if (_isContactAlreadySaved) {
                              setState(() => _isContactAlreadySaved = false);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Mobile Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        NeoCard(
                          child: CheckboxListTile(
                            value: _saveToDeviceContacts,
                            onChanged: _isContactAlreadySaved
                                ? null
                                : (val) => setState(
                                    () => _saveToDeviceContacts = val ?? false,
                                  ),
                            title: Text(
                              context.loc.save_contact_to_phone,
                              style: TextStyle(
                                color: _isContactAlreadySaved
                                    ? AppTheme.darkGrey
                                    : theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: _isContactAlreadySaved
                                ? Text(
                                    context.loc.already_in_contacts,
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
                      ],
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              text: 'Next: Measurements',
              onPressed: _onNext,
            ),
          ),
        ],
      ),
    );
  }
}
