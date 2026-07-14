import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _order;
  final _noteController = TextEditingController();

  // Status options matching backend Order stages
  final List<String> _statuses = [
    'Incoming',
    'Measuring',
    'Cutting',
    'Stitching',
    'Checking',
    'Ready',
    'Delivered',
    'Cancelled'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_order == null) {
      final orderId = ModalRoute.of(context)!.settings.arguments as String;
      _loadOrderDetails(orderId);
    }
  }

  Future<void> _loadOrderDetails(String orderId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _order = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      developer.log("Error loading order details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_order == null) return;
    final orderId = _order!['_id'] ?? _order!['id'];

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppTheme.trustGreen),
        );
        _loadOrderDetails(orderId);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty || _order == null) return;
    final orderId = _order!['_id'] ?? _order!['id'];

    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'text': noteText}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _noteController.clear();
        _loadOrderDetails(orderId);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to add note');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error adding note: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recordPayment() async {
    if (_order == null) return;
    final orderId = _order!['_id'] ?? _order!['id'];
    final amountController = TextEditingController();
    String method = 'Cash';

    final messenger = ScaffoldMessenger.of(context);
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCard,
              title: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brandPurple)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.darkCard,
                    // ignore: deprecated_member_use
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      labelStyle: TextStyle(color: AppTheme.darkGrey),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'UPI/Online', child: Text('UPI/Online', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Card', child: Text('Card', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => method = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.darkGrey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Record', style: TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (success != true) return;

    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'paymentType': method,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully'), backgroundColor: AppTheme.trustGreen),
        );
        _loadOrderDetails(orderId);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to record payment');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error recording payment: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _order != null ? 'Order details' : 'Loading...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: _order != null
            ? [
                PopupMenuButton<String>(
                  color: AppTheme.darkCard,
                  onSelected: _updateStatus,
                  itemBuilder: (context) {
                    return _statuses.map((status) {
                      return PopupMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _order!['status'] == status ? AppTheme.brandPurple : Colors.white,
                            fontWeight: _order!['status'] == status ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        (_order!['status'] ?? 'Incoming').toString().toUpperCase(),
                        style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _isLoading && _order == null
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Failed to load order', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Client Info NeoCard
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _order!['customerName'] ?? 'Walk-in Customer',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_order!['status'] ?? 'pending').withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (_order!['status'] ?? 'Incoming').toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(_order!['status'] ?? 'pending'),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Garment Category', _order!['garmentType'] ?? 'Custom Order'),
                            _infoRow('Fabric details', _order!['fabric'] ?? 'N/A'),
                            _infoRow(
                              'Due Date',
                              _order!['deliveryDate'] != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(_order!['deliveryDate']))
                                  : 'N/A',
                            ),
                            _infoRow('Assigned Staff', _order!['assignedKarigar']?['name'] ?? 'Not Assigned'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Measurements details if present
                      if (_order!['measurements'] != null) ...[
                        const Text('Measurements Snapshot', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        NeoCard(
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: _buildMeasurementChips(_order!['measurements']),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Invoices & Payments summary
                      const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Cost', style: TextStyle(color: AppTheme.darkGrey)),
                                Text('₹${_order!['price'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Paid', style: TextStyle(color: AppTheme.darkGrey)),
                                Text(
                                  '₹${_order!['payment']?['paidAmount'] ?? 0}',
                                  style: const TextStyle(color: AppTheme.trustGreen, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Balance Amount', style: TextStyle(color: AppTheme.darkGrey)),
                                Text(
                                  '₹${_order!['payment']?['balanceAmount'] ?? (_order!['price'] ?? 0)}',
                                  style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                                onPressed: _recordPayment,
                                icon: const Icon(Icons.payment, color: Colors.white),
                                label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes Timeline Mapped from Backend
                      const Text('Order Notes Timeline', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_order!['notes'] == null || (_order!['notes'] as List).isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No notes or timeline events recorded.', style: TextStyle(color: AppTheme.darkGrey)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (_order!['notes'] as List).length,
                                itemBuilder: (context, index) {
                                  final note = _order!['notes'][index];
                                  final dateStr = note['date'] != null
                                      ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(note['date']))
                                      : '';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.circle, size: 10, color: AppTheme.brandPurple),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(note['text'] ?? '', style: const TextStyle(color: Colors.white)),
                                              const SizedBox(height: 2),
                                              Text(dateStr, style: const TextStyle(color: AppTheme.darkGrey, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const Divider(color: Colors.white10, height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Add instruction or timeline note...',
                                      hintStyle: TextStyle(color: AppTheme.darkGrey),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, color: AppTheme.brandPurple),
                                  onPressed: _addNote,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.darkGrey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildMeasurementChips(Map<String, dynamic> measurements) {
    final chips = <Widget>[];
    measurements.forEach((key, val) {
      if (val != null && val is num && val > 0) {
        chips.add(
          Chip(
            backgroundColor: AppTheme.lightGrey,
            label: Text(
              '${key.toUpperCase()}: $val"',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    });
    if (chips.isEmpty) {
      chips.add(const Text('No measurement values saved', style: TextStyle(color: AppTheme.darkGrey)));
    }
    return chips;
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('incoming')) {
      return AppTheme.safetyOrange;
    } else if (s.contains('progress') || s.contains('stitching') || s.contains('cutting') || s.contains('measuring')) {
      return AppTheme.brandPurple;
    } else if (s.contains('ready') || s.contains('completed') || s.contains('checking')) {
      return AppTheme.trustGreen;
    } else if (s.contains('delivered')) {
      return AppTheme.brandPurple;
    }
    return AppTheme.darkGrey;
  }
}
