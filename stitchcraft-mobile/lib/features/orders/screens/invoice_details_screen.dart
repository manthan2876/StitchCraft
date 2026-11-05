import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/config/app_env.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/pdf_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class _InventoryChargeItem {
  final String itemName;
  final double quantity;
  final String unit;
  final double rate;
  final double totalCharge;

  _InventoryChargeItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.totalCharge,
  });
}

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
  String _shopUpi = '';
  String _shopGstin = '';

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
      _shopUpi = prefs.getString('shopUpi') ?? '';
      _shopGstin = prefs.getString('shopGstin') ?? '';
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _order = json.decode(response.body);
          });
        }
        return;
      }
    } catch (e) {
      developer.log("Remote invoice fetch note: $e; attempting local offline resolution");
    }

    // Local SQLite fallback
    try {
      final localDb = LocalDatabaseService();
      final localOrder = await localDb.getRecordById('orders', orderId);
      if (localOrder != null) {
        final liningItems = await localDb.getLiningItemsByOrder(orderId);
        final map = Map<String, dynamic>.from(localOrder);
        map['customerName'] = map['customer_name'];
        map['garmentType'] = map['item_types'] ?? 'Custom Order';
        map['price'] = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
        map['payment'] = {
          'paidAmount': (map['advance_amount'] as num?)?.toDouble() ?? 0.0,
          'balanceAmount': (((map['total_amount'] as num?)?.toDouble() ?? 0.0) -
                  ((map['advance_amount'] as num?)?.toDouble() ?? 0.0))
              .clamp(0.0, double.infinity),
        };

        if (liningItems.isNotEmpty) {
          final firstLining = liningItems.first;
          map['needsAster'] = true;
          map['asterQuantity'] = (firstLining['quantity'] as num?)?.toDouble() ?? 1.0;
          map['asterSellingPrice'] = (firstLining['unit_price'] as num?)?.toDouble() ?? 0.0;
          map['asterItemName'] = firstLining['material_type'] ?? 'Lining Stock';
        } else if (map['astar_required'] == 1 || (map['astar_cost'] as num? ?? 0) > 0) {
          map['needsAster'] = true;
          map['asterQuantity'] = 1.0;
          map['asterSellingPrice'] = (map['astar_cost'] as num?)?.toDouble() ?? 0.0;
          map['asterItemName'] = (map['astar_source'] != null && map['astar_source'] != 'Customer')
              ? map['astar_source']
              : 'Lining Material';
        }

        if (mounted) {
          setState(() {
            _order = map;
          });
        }
      }
    } catch (e) {
      developer.log("Error resolving local invoice: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_InventoryChargeItem> _getInventoryCharges(Map<String, dynamic> order) {
    final List<_InventoryChargeItem> items = [];

    final bool needsAster = order['needsAster'] == true || order['astar_required'] == 1;
    final double asterQty = (order['asterQuantity'] as num?)?.toDouble() ?? 0.0;
    final double asterPrice = (order['asterSellingPrice'] as num?)?.toDouble() ?? 0.0;
    final double astarCost = (order['astar_cost'] as num?)?.toDouble() ??
        (order['material_cost'] as num?)?.toDouble() ??
        0.0;

    String itemName = 'Lining / Aster Material';
    if (order['asterInventoryItem'] is Map) {
      itemName = order['asterInventoryItem']['itemName'] ??
          order['asterInventoryItem']['name'] ??
          itemName;
    } else if (order['asterItemName'] is String && (order['asterItemName'] as String).isNotEmpty) {
      itemName = order['asterItemName'] as String;
    } else if (order['astar_source'] is String &&
        (order['astar_source'] as String).isNotEmpty &&
        order['astar_source'] != 'Customer') {
      itemName = order['astar_source'] as String;
    }

    String unit = 'm';
    if (order['asterInventoryItem'] is Map && order['asterInventoryItem']['unit'] != null) {
      unit = order['asterInventoryItem']['unit'].toString();
    }

    if (needsAster) {
      final double total = asterQty > 0 && asterPrice > 0
          ? (asterQty * asterPrice)
          : (astarCost > 0 ? astarCost : 0.0);

      if (total > 0 || asterQty > 0) {
        items.add(_InventoryChargeItem(
          itemName: itemName,
          quantity: asterQty > 0 ? asterQty : 1.0,
          unit: unit,
          rate: asterPrice > 0 ? asterPrice : (total > 0 ? total : 0.0),
          totalCharge: total,
        ));
      }
    }

    // Check sub-items in multi-item orders
    if (order['items'] is List) {
      for (final it in (order['items'] as List)) {
        if (it is Map && (it['needsAster'] == true || it['astar_required'] == 1)) {
          final q = (it['asterQuantity'] as num?)?.toDouble() ?? 0.0;
          final p = (it['asterSellingPrice'] as num?)?.toDouble() ?? 0.0;
          final name = (it['asterItemName'] ?? it['liningName'] ?? 'Lining (${it['name'] ?? it['apparelType'] ?? 'Item'})').toString();
          if (q > 0 || p > 0) {
            items.add(_InventoryChargeItem(
              itemName: name,
              quantity: q > 0 ? q : 1.0,
              unit: 'm',
              rate: p,
              totalCharge: q * p,
            ));
          }
        }
      }
    }

    return items;
  }

  Future<void> _shareInvoiceWhatsApp() async {
    if (_order == null) return;

    final String customerName = _order!['customerName'] ?? 'Customer';
    final String customerPhone = _order!['customerPhone'] ?? _order!['customer']?['phone'] ?? '';
    final String orderId = _order!['_id'] ?? _order!['id'] ?? '';
    final String invoiceNumber = 'INV-${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length).toUpperCase()}';

    final inventoryCharges = _getInventoryCharges(_order!);
    final double totalInventory = inventoryCharges.fold(0.0, (sum, i) => sum + i.totalCharge);

    final double rawPrice = (_order!['price'] as num?)?.toDouble() ??
        (_order!['total_amount'] as num?)?.toDouble() ??
        0.0;

    final double stitchingPrice = (_order!['needsAster'] == true && _order!['asterQuantity'] != null && _order!['asterSellingPrice'] != null)
        ? rawPrice
        : (rawPrice > totalInventory && totalInventory > 0 ? rawPrice - totalInventory : rawPrice);

    final double billTotal = stitchingPrice + totalInventory;
    final double paid = (_order!['payment']?['paidAmount'] as num?)?.toDouble() ??
        (_order!['advance_amount'] as num?)?.toDouble() ??
        0.0;
    final double balance = (billTotal - paid).clamp(0.0, double.infinity);

    final String guestUrl = '${AppEnv.webInvoiceUrl}/invoice/share/$orderId';

    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number linked to this customer'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    final String materialBreakdown = inventoryCharges.isNotEmpty
        ? "• Inventory Material Added: ${inventoryCharges.map((c) => "${c.itemName} (+₹${c.totalCharge.toStringAsFixed(0)})").join(', ')}\n"
        : "";

    final String effectiveGstin = (_order!['shop']?['gstin'] ?? _shopGstin).toString().trim();
    final String effectiveUpi = (_order!['shop']?['upiId'] ?? _shopUpi).toString().trim();
    final String gstinLine = effectiveGstin.isNotEmpty ? "GSTIN: $effectiveGstin\n" : "";
    final String upiLine = effectiveUpi.isNotEmpty ? "UPI ID: $effectiveUpi\n" : "";

    final String message = "Hello $customerName, here is the invoice $invoiceNumber for your tailoring order at $_shopName.\n"
        "$gstinLine"
        "$upiLine\n"
        "• Stitching Service: ₹${stitchingPrice.toStringAsFixed(2)}\n"
        "$materialBreakdown"
        "Total Bill Amount: ₹${billTotal.toStringAsFixed(2)}\n"
        "Paid: ₹${paid.toStringAsFixed(2)}\n"
        "Balance Due: ₹${balance.toStringAsFixed(2)}\n\n"
        "View bill online: $guestUrl\n\n"
        "Thank you for choosing $_shopName!";

    final cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final targetPhone = cleanPhone.startsWith('91') || cleanPhone.length != 10 ? cleanPhone : '91$cleanPhone';
    final String url = "https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}";

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

    final inventoryCharges = _getInventoryCharges(_order!);
    final double totalInventory = inventoryCharges.fold(0.0, (sum, i) => sum + i.totalCharge);

    final double rawPrice = (_order!['price'] as num?)?.toDouble() ??
        (_order!['total_amount'] as num?)?.toDouble() ??
        0.0;

    final double stitchingPrice = (_order!['needsAster'] == true && _order!['asterQuantity'] != null && _order!['asterSellingPrice'] != null)
        ? rawPrice
        : (rawPrice > totalInventory && totalInventory > 0 ? rawPrice - totalInventory : rawPrice);

    final double billTotal = stitchingPrice + totalInventory;
    final double paid = (_order!['payment']?['paidAmount'] as num?)?.toDouble() ??
        (_order!['advance_amount'] as num?)?.toDouble() ??
        0.0;
    final double balance = (billTotal - paid).clamp(0.0, double.infinity);

    final String guestUrl = '${AppEnv.webInvoiceUrl}/invoice/share/$orderId';

    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number linked to this customer'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    final String message = "Dear $customerName, friendly reminder regarding outstanding balance of ₹${balance.toStringAsFixed(2)} for invoice $invoiceNumber at $_shopName.\n\n"
        "View bill: $guestUrl\n\n"
        "Thank you, $_shopName.";

    final cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final targetPhone = cleanPhone.startsWith('91') || cleanPhone.length != 10 ? cleanPhone : '91$cleanPhone';
    final String url = "https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}";

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

  Future<void> _downloadInvoicePdf() async {
    if (_order == null) return;
    await PdfService.generateInvoiceFromMap(_order!, _shopName, share: false);
  }

  Future<void> _sendInvoicePdf() async {
    if (_order == null) return;
    await PdfService.generateInvoiceFromMap(_order!, _shopName, share: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderId = _order != null ? (_order!['_id'] ?? _order!['id'] ?? '') : '';
    final String title = _order != null
        ? 'Invoice #${orderId.substring(0, orderId.length > 5 ? 5 : orderId.length).toUpperCase()}'
        : 'Loading Invoice...';

    final inventoryCharges = _order != null ? _getInventoryCharges(_order!) : <_InventoryChargeItem>[];
    final double totalInventoryCharges = inventoryCharges.fold(0.0, (sum, i) => sum + i.totalCharge);

    final double rawPrice = _order != null
        ? ((_order!['price'] as num?)?.toDouble() ??
            (_order!['total_amount'] as num?)?.toDouble() ??
            0.0)
        : 0.0;

    final double stitchingBasePrice = (_order != null && _order!['needsAster'] == true && _order!['asterQuantity'] != null && _order!['asterSellingPrice'] != null)
        ? rawPrice
        : (rawPrice > totalInventoryCharges && totalInventoryCharges > 0
            ? rawPrice - totalInventoryCharges
            : rawPrice);

    final double effectiveBillTotal = stitchingBasePrice + totalInventoryCharges;

    final double paid = _order != null
        ? ((_order!['payment']?['paidAmount'] as num?)?.toDouble() ??
            (_order!['advance_amount'] as num?)?.toDouble() ??
            0.0)
        : 0.0;

    final double balance = (effectiveBillTotal - paid).clamp(0.0, double.infinity);
    final bool isPaid = balance <= 0.01;

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
                                    if ((_order!['shop']?['gstin'] ?? _shopGstin).toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'GSTIN: ${(_order!['shop']?['gstin'] ?? _shopGstin).toString().trim()}',
                                        style: const TextStyle(
                                          color: AppTheme.darkGrey,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if ((_order!['shop']?['upiId'] ?? _shopUpi).toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'UPI: ${(_order!['shop']?['upiId'] ?? _shopUpi).toString().trim()}',
                                        style: const TextStyle(
                                          color: AppTheme.darkGrey,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const Text('StitchCraft Tailoring Bill', style: TextStyle(color: AppTheme.darkGrey, fontSize: 13)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? AppTheme.trustGreen : AppTheme.safetyOrange)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isPaid ? 'PAID' : 'DUE',
                                    style: TextStyle(
                                      color: isPaid ? AppTheme.trustGreen : AppTheme.safetyOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            _infoRow('Client Name', _order!['customerName'] ?? 'Walk-in Customer'),
                            _infoRow('Garment Category', _order!['garmentType'] ?? _order!['apparelType'] ?? 'Custom Order'),
                            _infoRow('Fabric Description', _order!['fabric'] ?? 'Customer Provided'),
                            _infoRow(
                              'Billing Date',
                              _order!['createdAt'] != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(_order!['createdAt']))
                                  : DateFormat('dd MMM yyyy').format(DateTime.now()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bill Items & Inventory Breakdown
                      Text(
                        'Invoice Items & Inventory Charges',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Stitching Service Item
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandPurple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.content_cut, size: 18, color: AppTheme.brandPurple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_order!['garmentType'] ?? _order!['apparelType'] ?? 'Custom'} Stitching',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Custom Tailoring Package • ${_order!['fabric'] ?? 'Customer Provided'}',
                                        style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.formatINR(stitchingBasePrice),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            // 2. Inventory Material Additions (if any)
                            if (inventoryCharges.isNotEmpty) ...[
                              const Divider(height: 20),
                              Text(
                                'INVENTORY STOCK ADDED TO TOTAL:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...inventoryCharges.map((inv) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandPurple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.brandPurple.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandPurple.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.inventory_2, size: 16, color: AppTheme.brandPurple),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  inv.itemName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.trustGreen.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'From Shop Stock',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.trustGreen,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Quantity: ${inv.quantity} ${inv.unit} @ ${CurrencyUtils.formatINR(inv.rate, showDecimals: false)}/${inv.unit}',
                                            style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '+${CurrencyUtils.formatINR(inv.totalCharge)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.trustGreen,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cost totals NeoCard
                      Text(
                        context.loc.total_charges,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Stitching Charge', CurrencyUtils.formatINR(stitchingBasePrice)),
                            if (totalInventoryCharges > 0)
                              _infoRow(
                                'Inventory Material Added',
                                '+${CurrencyUtils.formatINR(totalInventoryCharges)}',
                              ),
                            const Divider(height: 16),
                            _infoRow(context.loc.total_amount, CurrencyUtils.formatINR(effectiveBillTotal)),
                            _infoRow(context.loc.paid_amount, CurrencyUtils.formatINR(paid)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.loc.balance_amount_due, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                Text(
                                  CurrencyUtils.formatINR(balance),
                                  style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Direct UPI Payment Card
                      _buildUpiPaymentCard(
                        theme,
                        balance,
                      ),
                      const SizedBox(height: 16),

                      // WhatsApp actions
                      Text('Communication Actions', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp color
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _shareInvoiceWhatsApp,
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share Invoice'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _sendReminderWhatsApp,
                              icon: const Icon(Icons.notifications_active_outlined, size: 18),
                              label: const Text('Send Reminder'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // PDF Actions
                      Text('PDF Actions', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _downloadInvoicePdf,
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Download PDF'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _sendInvoicePdf,
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('Share PDF'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUpiPaymentCard(ThemeData theme, double balanceDue) {
    if (balanceDue <= 0) {
      return const SizedBox.shrink();
    }

    final rawShopUpi = (_order?['shop']?['upiId'] ?? _shopUpi).toString().trim();
    final effectiveUpi = rawShopUpi.isNotEmpty ? rawShopUpi : 'merchant@upi';
    final customerName = _order?['customerName'] ?? 'Customer';
    final orderId = _order?['_id'] ?? _order?['id'] ?? '';
    final formattedBalance = balanceDue.toStringAsFixed(2);
    final upiUrl = 'upi://pay?pa=$effectiveUpi&pn=${Uri.encodeComponent(_shopName)}&am=$formattedBalance&cu=INR&tn=${Uri.encodeComponent('Tailoring Bill #$orderId')}';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(upiUrl)}';

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 76,
                  height: 76,
                  color: Colors.white,
                  padding: const EdgeInsets.all(4),
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.qr_code_2, color: Colors.black87, size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collect Balance: ${CurrencyUtils.formatINR(balanceDue)}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan Pay QR or direct UPI for $customerName',
                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UPI ID: $effectiveUpi',
                      style: const TextStyle(
                        color: AppTheme.trustGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.trustGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final uri = Uri.parse(upiUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No supported UPI app found on device')),
                  );
                }
              },
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Open UPI App to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
