import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  const InvoiceDetailsScreen({super.key});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _order;
  String _shopName = 'StitchCraft';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_order == null) {
      final orderId = ModalRoute.of(context)!.settings.arguments as String;
      _loadOrderDetails(orderId);
      _loadShopName();
    }
  }

  Future<void> _loadShopName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopName = prefs.getString('shopName') ?? 'StitchCraft';
    });
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
        throw Exception('Failed to load invoice details');
      }
    } catch (e) {
      developer.log("Error loading invoice: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoice: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareInvoiceWhatsApp() async {
    if (_order == null) return;

    final String customerName = _order!['customerName'] ?? 'Customer';
    final String customerPhone = _order!['customerPhone'] ?? _order!['customer']?['phone'] ?? '';
    final String orderId = _order!['_id'] ?? _order!['id'] ?? '';
    final String invoiceNumber = 'INV-${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length).toUpperCase()}';
    
    final double total = (_order!['price'] as num?)?.toDouble() ?? 0.0;
    final double paid = (_order!['payment']?['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final double balance = (_order!['payment']?['balanceAmount'] as num?)?.toDouble() ?? total;
    
    final String guestUrl = 'https://stitchcraft-frontend.onrender.com/invoice/share/$orderId';

    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number linked to this customer'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    final String message = "Hello $customerName, here is the invoice $invoiceNumber for your tailoring order at $_shopName.\n\n"
        "Total Amount: ₹${total.toStringAsFixed(2)}\n"
        "Paid: ₹${paid.toStringAsFixed(2)}\n"
        "Balance: ₹${balance.toStringAsFixed(2)}\n\n"
        "View bill: $guestUrl\n\n"
        "Thank you for choosing $_shopName!";

    final String url = "https://wa.me/91$customerPhone?text=${Uri.encodeComponent(message)}";
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    }
  }

  Future<void> _sendReminderWhatsApp() async {
    if (_order == null) return;

    final String customerName = _order!['customerName'] ?? 'Customer';
    final String customerPhone = _order!['customerPhone'] ?? _order!['customer']?['phone'] ?? '';
    final String orderId = _order!['_id'] ?? _order!['id'] ?? '';
    final String invoiceNumber = 'INV-${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length).toUpperCase()}';
    
    final double total = (_order!['price'] as num?)?.toDouble() ?? 0.0;
    final double balance = (_order!['payment']?['balanceAmount'] as num?)?.toDouble() ?? total;
    
    final String guestUrl = 'https://stitchcraft-frontend.onrender.com/invoice/share/$orderId';

    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number linked to this customer'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    final String message = "Dear $customerName, friendly reminder regarding outstanding balance of ₹${balance.toStringAsFixed(2)} for invoice $invoiceNumber at $_shopName.\n\n"
        "View bill: $guestUrl\n\n"
        "Thank you, $_shopName.";

    final String url = "https://wa.me/91$customerPhone?text=${Uri.encodeComponent(message)}";
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderId = _order != null ? (_order!['_id'] ?? _order!['id'] ?? '') : '';
    final String title = _order != null
        ? 'Invoice #${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length).toUpperCase()}'
        : 'Loading Invoice...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading && _order == null
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Failed to load invoice', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client / Shop details NeoCard
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _shopName,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const Text('StitchCraft Tailoring Bill', style: TextStyle(color: AppTheme.darkGrey, fontSize: 13)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ((_order!['payment']?['balanceAmount'] ?? 1.0) == 0.0
                                            ? AppTheme.trustGreen
                                            : AppTheme.safetyOrange)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (_order!['payment']?['balanceAmount'] ?? 1.0) == 0.0 ? 'PAID' : 'DUE',
                                    style: TextStyle(
                                      color: (_order!['payment']?['balanceAmount'] ?? 1.0) == 0.0
                                          ? AppTheme.trustGreen
                                          : AppTheme.safetyOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Client Name', _order!['customerName'] ?? 'Walk-in Customer'),
                            _infoRow('Garment Category', _order!['garmentType'] ?? 'Custom Order'),
                            _infoRow('Fabric Description', _order!['fabric'] ?? 'N/A'),
                            _infoRow(
                              'Billing Date',
                              _order!['createdAt'] != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(_order!['createdAt']))
                                  : 'N/A',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cost totals NeoCard
                      const Text('Total Charges', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Total Bill Amount', '₹${_order!['price'] ?? 0}'),
                            _infoRow('Total Paid', '₹${_order!['payment']?['paidAmount'] ?? 0}'),
                            const Divider(color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Balance Amount Due', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${_order!['payment']?['balanceAmount'] ?? (_order!['price'] ?? 0)}',
                                  style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // WhatsApp actions
                      const Text('Communication Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp color
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _shareInvoiceWhatsApp,
                              icon: const Icon(Icons.share, color: Colors.white),
                              label: const Text('Share Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPurple,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _sendReminderWhatsApp,
                              icon: const Icon(Icons.notifications_active, color: Colors.white),
                              label: const Text('Send Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
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
}
