import 'dart:convert';
import 'dart:io';
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
      final file = File(localPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${localPath.split(Platform.pathSeparator).last}';
      final token = await _authService.getToken();
      if (token == null) return null;

      // 1. Get signed upload URL from backend
      final urlResponse = await http.post(
        Uri.parse('${AuthService.baseUrl}/upload/get-upload-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bucketName': bucketName,
          'fileName': fileName,
        }),
      );

      if (urlResponse.statusCode != 200 && urlResponse.statusCode != 201) {
        throw Exception("Failed to get upload URL: ${urlResponse.body}");
      }

      final urlData = json.decode(urlResponse.body);
      final signedUrl = urlData['signedUrl'] as String?;
      if (signedUrl == null) {
        throw Exception("Signed URL not found in response: ${urlResponse.body}");
      }

      // 2. Put bytes directly to Supabase storage
      final uploadResponse = await http.put(
        Uri.parse(signedUrl),
        headers: {
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
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
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
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

      // Upload sample photo if present
      String maapImageUrl = '';
      if (_wizardData!['samplePhotoPath'] != null) {
        final uploaded = await _uploadFile(_wizardData!['samplePhotoPath'] as String, 'maap-images');
        if (uploaded != null) {
          maapImageUrl = uploaded;
        }
      }

      // Upload fabric photo if present
      String fabricImageUrl = '';
      if (_wizardData!['fabricPhotoPath'] != null) {
        final uploaded = await _uploadFile(_wizardData!['fabricPhotoPath'] as String, 'maap-images');
        if (uploaded != null) {
          fabricImageUrl = uploaded;
        }
      }

      // 2. Prepare payload details
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final double advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;
      final String rawGarmentType = _wizardData!['garmentType'] ?? 'Shirt';

      final orderPayload = {
        'customerId': customerId,
        'customerName': _wizardData!['newCustomer'] != null
            ? _wizardData!['newCustomer']['name']
            : _wizardData!['customer']['name'],
        'customerPhone': _wizardData!['newCustomer'] != null
            ? _wizardData!['newCustomer']['phone']
            : _wizardData!['customer']['phone'],
        'apparelType': _mapApparelType(rawGarmentType),
        'price': price,
        'advancePaid': advance,
        'fabric': _wizardData!['fabricSource'] ?? 'Customer',
        'measurements': _wizardData!['measurements'] ?? {},
        'measurementType': _wizardData!['measurementType'] == 'body' ? 'Measurements' : 'Maap',
        'maapImageUrl': maapImageUrl,
        'fabricImageUrl': fabricImageUrl,
        'deliveryDate': _dueDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'status': 'Incoming',
        'needsAster': _wizardData!['needsLining'] ?? false,
        'asterQuantity': _wizardData!['needsLining'] == true ? (_wizardData!['liningQtyUsed'] ?? 0) : 0,
        'asterInventoryItem': (_wizardData!['needsLining'] == true && _wizardData!['liningItem'] != null)
            ? _wizardData!['liningItem']['_id']
            : null,
        'asterSellingPrice': (_wizardData!['needsLining'] == true && _wizardData!['liningItem'] != null)
            ? (_wizardData!['liningItem']['costPerUnit'] ?? 0)
            : 0,
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

        messenger.showSnackBar(
          const SnackBar(content: Text('Tailoring Order created successfully!'), backgroundColor: AppTheme.trustGreen),
        );
        nav.popUntil(ModalRoute.withName('/home'));
      } else {
        throw Exception(json.decode(orderResponse.body)['message'] ?? 'Failed to save order');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error creating order: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                          // ignore: deprecated_member_use
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
                          // ignore: deprecated_member_use
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
