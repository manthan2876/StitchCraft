import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _wizardData;

  final _priceController = TextEditingController(text: '800');
  final _advanceController = TextEditingController(text: '200');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  List<dynamic> _karigars = [];
  Map<String, dynamic>? _selectedKarigar;

  List<dynamic> _machines = [];
  Map<String, dynamic>? _selectedMachine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wizardData == null) {
      _wizardData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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

      final kResponse = await http.get(Uri.parse('${AuthService.baseUrl}/karigars'), headers: headers);
      final mResponse = await http.get(Uri.parse('${AuthService.baseUrl}/machines'), headers: headers);

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.brandPurple,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
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

  Future<void> _confirmAndCreateOrder() async {
    if (_wizardData == null) return;
    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String? customerId;

      // 1. If it's a new customer, save them first
      if (_wizardData!['newCustomer'] != null) {
        final newCust = _wizardData!['newCustomer'] as Map<String, dynamic>;
        final custResponse = await http.post(
          Uri.parse('${AuthService.baseUrl}/customers'),
          headers: headers,
          body: json.encode({
            'name': newCust['name'],
            'phone': newCust['phone'],
          }),
        );

        if (custResponse.statusCode == 200 || custResponse.statusCode == 201) {
          final custData = json.decode(custResponse.body);
          customerId = custData['_id'] ?? custData['id'];
        } else {
          throw Exception('Failed to register new customer in MongoDB Atlas');
        }
      } else if (_wizardData!['customer'] != null) {
        customerId = _wizardData!['customer']['_id'] ?? _wizardData!['customer']['id'];
      }

      if (customerId == null) {
        throw Exception('Customer profile is missing or failed to initialize');
      }

      // 2. Prepare payload details
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final double advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;

      final orderPayload = {
        'customer': customerId,
        'customerName': _wizardData!['newCustomer'] != null
            ? _wizardData!['newCustomer']['name']
            : _wizardData!['customer']['name'],
        'customerPhone': _wizardData!['newCustomer'] != null
            ? _wizardData!['newCustomer']['phone']
            : _wizardData!['customer']['phone'],
        'garmentType': _wizardData!['garmentType'],
        'price': price,
        'advance': advance,
        'fabric': _wizardData!['fabricSource'] ?? 'Customer',
        'measurements': _wizardData!['measurements'] ?? {},
        'measurementType': _wizardData!['measurementType'] ?? 'body',
        'dueDate': _dueDate.toIso8601String(),
        'status': 'pending',
        'paymentStatus': advance >= price ? 'paid' : (advance > 0 ? 'partially_paid' : 'unpaid'),
        if (_selectedKarigar != null) 'assignedKarigar': _selectedKarigar!['_id'],
        if (_selectedMachine != null) 'assignedMachine': _selectedMachine!['_id'],
      };

      // 3. Save order to backend
      final orderResponse = await http.post(
        Uri.parse('${AuthService.baseUrl}/orders'),
        headers: headers,
        body: json.encode(orderPayload),
      );

      if (orderResponse.statusCode == 200 || orderResponse.statusCode == 201) {
        // 4. If lining stock was used, decrement the count
        if (_wizardData!['needsLining'] == true && _wizardData!['liningItem'] != null) {
          final lining = _wizardData!['liningItem'] as Map<String, dynamic>;
          final double usedQty = _wizardData!['liningQtyUsed'] as double;
          final double oldQty = (lining['quantity'] as num).toDouble();
          final double newQty = oldQty - usedQty;

          await http.put(
            Uri.parse('${AuthService.baseUrl}/inventory/${lining['_id']}'),
            headers: headers,
            body: json.encode({
              'itemName': lining['itemName'],
              'itemType': lining['itemType'] ?? 'Lining',
              'quantity': newQty >= 0 ? newQty : 0.0,
              'unit': lining['unit'] ?? 'meters',
              'costPerUnit': lining['costPerUnit'] ?? 0.0,
              'minQuantity': lining['minQuantity'] ?? 5.0,
            }),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tailoring Order created successfully!'), backgroundColor: AppTheme.trustGreen),
        );
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      } else {
        throw Exception(json.decode(orderResponse.body)['message'] ?? 'Failed to save order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm Details'),
      ),
      body: _isLoading && _karigars.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Financial details card
                  const Text('Price & Advance Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Total Price (₹)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _advanceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Paid Advance (₹)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Date Details Card
                  const Text('Delivery Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  NeoCard(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.brandPurple),
                      title: Text(
                        DateFormat('dd MMMM yyyy (EEEE)').format(_dueDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined, color: Colors.white),
                      onTap: () => _selectDueDate(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Staff & Machine Assignment Card
                  const Text('Workshop Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  NeoCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<Map<String, dynamic>>(
                          dropdownColor: AppTheme.darkCard,
                          decoration: const InputDecoration(labelText: 'Assign Karigar (Staff)'),
                          value: _selectedKarigar,
                          items: _karigars.map((k) {
                            final name = k['name'] ?? 'Staff';
                            final specialty = k['specialty'] ?? 'All';
                            return DropdownMenuItem(
                              value: k as Map<String, dynamic>,
                              child: Text('$name ($specialty)', style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedKarigar = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          dropdownColor: AppTheme.darkCard,
                          decoration: const InputDecoration(labelText: 'Assign Sewing Machine'),
                          value: _selectedMachine,
                          items: _machines.map((m) {
                            final name = m['name'] ?? 'Machine';
                            return DropdownMenuItem(
                              value: m as Map<String, dynamic>,
                              child: Text(name, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedMachine = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  PrimaryButton(
                    text: 'Confirm & Place Order',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _confirmAndCreateOrder,
                  ),
                ],
              ),
            ),
    );
  }
}
