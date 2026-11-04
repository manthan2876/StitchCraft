import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/device_contacts_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _wizardData;

  final _priceController = TextEditingController();
  final _advanceController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  List<dynamic> _karigars = [];
  Map<String, dynamic>? _selectedKarigar;

  List<dynamic> _machines = [];
  Map<String, dynamic>? _selectedMachine;

  String _mapApparelType(String garmentType) {
    final lower = garmentType.toLowerCase();
    if (lower.contains('shirt')) return 'Shirt';
    if (lower.contains('pant') || lower.contains('trouser')) return 'Pants';
    if (lower.contains('kurta') || lower.contains('kurti')) return 'Kurta';
    if (lower.contains('blouse')) return 'Blouse';
    if (lower.contains('lehenga')) return 'Lehenga';
    return 'Suit'; // Default fallback for Suit, Safari, Baba Suit, Frock, School Uniform, Salwar
  }

  Future<String?> _uploadFile(String localPath, String bucketName) async {
    try {
      final Uint8List bytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(localPath));
        bytes = response.bodyBytes;
      } else {
        final file = File(localPath);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last.split('\\').last}';
      final token = await _authService.getToken();
      if (token == null) return null;

      // 1. Get signed upload URL from backend
      final urlResponse = await http.post(
        Uri.parse('${AuthService.baseUrl}/upload/get-upload-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'bucketName': bucketName, 'fileName': fileName}),
      );

      if (urlResponse.statusCode != 200 && urlResponse.statusCode != 201) {
        throw Exception("Failed to get upload URL: ${urlResponse.body}");
      }

      final urlData = json.decode(urlResponse.body);
      final signedUrl = urlData['signedUrl'] as String?;
      if (signedUrl == null) {
        throw Exception(
          "Signed URL not found in response: ${urlResponse.body}",
        );
      }

      // 2. Put bytes directly to Supabase storage
      final uploadResponse = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        return fileName;
      } else {
        throw Exception("Supabase upload failed: ${uploadResponse.body}");
      }
    } catch (e) {
      developer.log("Error uploading file: $e");
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      _wizardData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _loadStaffAndMachines();
    }
  }

  Future<void> _loadStaffAndMachines() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final kResponse = await http.get(
        Uri.parse('${AuthService.baseUrl}/karigars'),
        headers: headers,
      );
      final mResponse = await http.get(
        Uri.parse('${AuthService.baseUrl}/machines'),
        headers: headers,
      );

      if (kResponse.statusCode == 200 && mResponse.statusCode == 200) {
        setState(() {
          _karigars = json.decode(kResponse.body) as List;
          _machines = json.decode(mResponse.body) as List;
        });
      }
    } catch (e) {
      developer.log("Error loading confirmation lists: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.brandPurple,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkCard,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.brandPurple,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1D2939),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndCreateOrder() async {
    if (_wizardData == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final price = double.tryParse(_priceController.text.trim());
    final advance = double.tryParse(_advanceController.text.trim());
    if (price == null || price <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enter a valid total price'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }
    if (advance == null || advance < 0 || advance > price) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Advance must be between ₹0 and the total price'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    String customerId = '';
    String customerName = '';
    String customerPhone = '';

    if (_wizardData!['newCustomer'] != null) {
      final newCust = _wizardData!['newCustomer'] as Map<String, dynamic>;
      customerName = newCust['name'] ?? '';
      customerPhone = newCust['phone'] ?? '';
      customerId = 'CUST-$nowMs';
    } else if (_wizardData!['customer'] != null) {
      final cust = _wizardData!['customer'] as Map<String, dynamic>;
      customerId = cust['_id'] ?? cust['id'] ?? 'CUST-$nowMs';
      customerName = cust['name'] ?? '';
      customerPhone = cust['phone'] ?? '';
    }

    final String rawGarmentType = _wizardData!['garmentType'] ?? 'Shirt';
    final localOrderId = 'ORD-$nowMs';

    // 1. Save Customer locally if new (deduplicate by phone number)
    if (_wizardData!['newCustomer'] != null) {
      try {
        final existingCustomers = await LocalDatabaseService().getRecords('customers');
        final cleanPhone = PhoneUtils.sanitizePhoneNumber(customerPhone);
        final match = existingCustomers.firstWhere(
          (c) => PhoneUtils.sanitizePhoneNumber(c['phone']?.toString() ?? '') == cleanPhone,
          orElse: () => {},
        );
        if (match.isNotEmpty && match['id'] != null) {
          customerId = match['id'].toString();
          await LocalDatabaseService().updateRecord('customers', customerId, {
            'name': customerName,
            'updated_at': nowMs,
          });
        } else {
          await LocalDatabaseService().insertRecord('customers', {
            'id': customerId,
            'name': customerName,
            'phone': customerPhone,
            'sync_status': 1,
            'updated_at': nowMs,
          });
        }
        if ((_wizardData!['newCustomer'] as Map)['saveToDeviceContacts'] == true) {
          DeviceContactsService().saveContactToPhone(
            fullName: customerName,
            phoneNumber: customerPhone,
          );
        }
      } catch (e) {
        developer.log("Local customer insert note: $e");
      }
    }

    // 2. Save Order locally first (Offline-First guarantees zero data loss)
    final localOrderRecord = {
      'id': localOrderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'order_date': nowMs,
      'due_date': _dueDate.millisecondsSinceEpoch,
      'status': 'Incoming',
      'total_amount': price,
      'advance_amount': advance,
      'description': '$rawGarmentType (${_wizardData!['fabricSource'] ?? 'Customer'})',
      'item_types': rawGarmentType,
      'is_rush': 0,
      'payment_method': 'Cash',
      'labor_cost': price * 0.7,
      'material_cost': (_wizardData!['needsLining'] == true && _wizardData!['liningItem'] != null)
          ? (_wizardData!['liningItem']['costPerUnit'] ?? 0.0)
          : 0.0,
      'overhead_cost': 0.0,
      'astar_required': _wizardData!['needsLining'] == true ? 1 : 0,
      'astar_source': _wizardData!['fabricSource'] ?? 'Customer',
      'astar_cost': (_wizardData!['needsLining'] == true && _wizardData!['liningItem'] != null)
          ? (_wizardData!['liningItem']['costPerUnit'] ?? 0.0)
          : 0.0,
      'fabric_photo_url': _wizardData!['fabricPhotoPath'] ?? '',
      'sync_status': 1,
      'updated_at': nowMs,
    };

    try {
      await LocalDatabaseService().insertRecord('orders', localOrderRecord);
    } catch (e) {
      developer.log("Local order insert note: $e");
    }

    // 3. Attempt server sync
    bool syncedWithServer = false;
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        if (_wizardData!['newCustomer'] != null) {
          try {
            final custIdempotencyKey = 'cust_$customerId';
            final custResponse = await http.post(
              Uri.parse('${AuthService.baseUrl}/customers'),
              headers: {
                ...headers,
                'Idempotency-Key': custIdempotencyKey,
              },
              body: json.encode({
                'name': customerName,
                'phone': customerPhone,
                'idempotencyKey': custIdempotencyKey,
              }),
            ).timeout(const Duration(seconds: 8));

            if (custResponse.statusCode == 200 || custResponse.statusCode == 201) {
              final custData = json.decode(custResponse.body);
              final remoteCustId = custData['_id'] ?? custData['id'];
              if (remoteCustId != null) {
                if (remoteCustId != customerId) {
                  await LocalDatabaseService().updateRecordId('customers', customerId, remoteCustId);
                } else {
                  await LocalDatabaseService().updateSyncStatus('customers', customerId, 0);
                }
                customerId = remoteCustId;
              }
            }
          } catch (e) {
            developer.log("Server customer sync note: $e");
          }
        }

        String maapImageUrl = '';
        if (_wizardData!['samplePhotoPath'] != null) {
          final uploaded = await _uploadFile(
            _wizardData!['samplePhotoPath'] as String,
            'maap-images',
          );
          if (uploaded != null) maapImageUrl = uploaded;
        }

        String fabricImageUrl = '';
        if (_wizardData!['fabricPhotoPath'] != null) {
          final uploaded = await _uploadFile(
            _wizardData!['fabricPhotoPath'] as String,
            'maap-images',
          );
          if (uploaded != null) fabricImageUrl = uploaded;
        }

        final orderIdempotencyKey = 'order_$localOrderId';
        final orderPayload = {
          'customerId': customerId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'apparelType': _mapApparelType(rawGarmentType),
          'price': price,
          'advancePaid': advance,
          'fabric': _wizardData!['fabricSource'] ?? 'Customer',
          'measurements': _wizardData!['measurements'] ?? {},
          'measurementType': _wizardData!['measurementType'] == 'body'
              ? 'Measurements'
              : 'Maap',
          'maapImageUrl': maapImageUrl,
          'fabricImageUrl': fabricImageUrl,
          'deliveryDate': _dueDate.toIso8601String().split('T')[0],
          'status': 'Incoming',
          'needsAster': _wizardData!['needsLining'] ?? false,
          'asterQuantity': _wizardData!['needsLining'] == true
              ? (_wizardData!['liningQtyUsed'] ?? 0)
              : 0,
          'asterInventoryItem':
              (_wizardData!['needsLining'] == true &&
                  _wizardData!['liningItem'] != null)
              ? _wizardData!['liningItem']['_id']
              : null,
          'asterSellingPrice':
              (_wizardData!['needsLining'] == true &&
                  _wizardData!['liningItem'] != null)
              ? (_wizardData!['liningItem']['costPerUnit'] ?? 0)
              : 0,
          if (_selectedKarigar != null)
            'assignedKarigar': _selectedKarigar!['_id'],
          if (_selectedMachine != null)
            'assignedMachine': _selectedMachine!['_id'],
          'idempotencyKey': orderIdempotencyKey,
        };

        final orderResponse = await http.post(
          Uri.parse('${AuthService.baseUrl}/orders'),
          headers: {
            ...headers,
            'Idempotency-Key': orderIdempotencyKey,
          },
          body: json.encode(orderPayload),
        ).timeout(const Duration(seconds: 10));

        if (orderResponse.statusCode == 200 || orderResponse.statusCode == 201) {
          syncedWithServer = true;
          try {
            final orderData = json.decode(orderResponse.body);
            final remoteId = orderData['_id'] ?? orderData['id'];
            final remoteOrderId = orderData['orderId'];

            if (remoteId != null && remoteId != localOrderId) {
              await LocalDatabaseService().updateRecordId('orders', localOrderId, remoteId);
            }
            final effectiveId = remoteId ?? localOrderId;
            await LocalDatabaseService().updateSyncStatus('orders', effectiveId, 0);
            if (remoteOrderId != null) {
              await LocalDatabaseService().updateRecord('orders', effectiveId, {
                'order_id': remoteOrderId,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              });
            }
          } catch (e) {
            developer.log("Error reconciling remote order ID: $e");
          }
        }
      }
    } catch (e) {
      developer.log("Backend sync skipped/failed (will sync later): $e");
    }

    // Clear saved draft on successful completion (UX-04)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_order_wizard');
    } catch (_) {}

    if (syncedWithServer) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order placed and synced successfully!'),
          backgroundColor: AppTheme.trustGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order saved locally! It will sync automatically when online.'),
          backgroundColor: AppTheme.warmAmber,
        ),
      );
    }
    nav.popUntil(ModalRoute.withName('/home'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('New order · 5 of 5 · Review & Confirm')),
      body: _isLoading && _karigars.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildOrderSummaryCard(theme),
                  const SizedBox(height: 16),

                  // Financial details card
                  Text(
                    'Price & Advance Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeoCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Total Price (₹)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _advanceController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Paid Advance (₹)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceSummary(theme),
                  const SizedBox(height: 16),

                  // Delivery Date Details Card
                  Text(
                    'Delivery Due Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeoCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.brandPurple,
                      ),
                      title: Text(
                        DateFormat('dd MMMM yyyy (EEEE)').format(_dueDate),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(
                        Icons.edit_calendar_outlined,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onTap: () => _selectDueDate(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Staff & Machine Assignment Card
                  Text(
                    'Workshop Assignment (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeoCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Assign Karigar (Staff)',
                          ),
                          // ignore: deprecated_member_use
                          value: _selectedKarigar,
                          items: _karigars.map((k) {
                            final name = k['name'] ?? 'Staff';
                            final specialty = k['specialty'] ?? 'All';
                            return DropdownMenuItem(
                              value: k as Map<String, dynamic>,
                              child: Text(
                                '$name ($specialty)',
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedKarigar = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Assign Sewing Machine',
                          ),
                          // ignore: deprecated_member_use
                          value: _selectedMachine,
                          items: _machines.map((m) {
                            final name = m['name'] ?? 'Machine';
                            return DropdownMenuItem(
                              value: m as Map<String, dynamic>,
                              child: Text(
                                name,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMachine = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: 'Confirm & Place Order',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _confirmAndCreateOrder,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme) {
    if (_wizardData == null) return const SizedBox.shrink();

    final customer = _wizardData!['newCustomer'] ?? _wizardData!['customer'];
    final custName = customer != null ? (customer['name'] ?? 'Walk-in') : 'Customer';
    final custPhone = customer != null ? (customer['phone'] ?? '') : '';
    final garment = _wizardData!['garmentType'] ?? 'Shirt';
    final fabricSource = _wizardData!['fabricSource'] ?? 'Customer Provided';
    final isBody = _wizardData!['measurementType'] == 'body';
    final measurements = _wizardData!['measurements'] as Map<String, dynamic>? ?? {};
    final needsLining = _wizardData!['needsLining'] == true;
    final liningItem = _wizardData!['liningItem'] as Map<String, dynamic>?;
    final liningQty = _wizardData!['liningQtyUsed'] ?? 0;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.brandPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garment,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$custName ${custPhone.isNotEmpty ? "• $custPhone" : ""}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _summaryRow(theme, Icons.straighten_outlined, 'Measurements', isBody ? '${measurements.length} points recorded' : 'Sample Garment (Maap)'),
          const SizedBox(height: 8),
          _summaryRow(theme, Icons.texture_outlined, 'Fabric Source', fabricSource),
          if (needsLining) ...[
            const SizedBox(height: 8),
            _summaryRow(
              theme,
              Icons.layers_outlined,
              'Lining (Aster)',
              '${liningItem?['itemName'] ?? 'Standard'} (${liningQty}m)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(ThemeData theme) {
    final total = double.tryParse(_priceController.text) ?? 0;
    final advance = double.tryParse(_advanceController.text) ?? 0;
    final balance = (total - advance).clamp(0, double.infinity);
    return NeoCard(
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppTheme.trustGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Balance after advance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '₹${balance.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.trustGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
