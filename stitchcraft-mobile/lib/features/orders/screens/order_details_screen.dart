import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';
import 'package:stitchcraft/core/widgets/record_payment_sheet.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:stitchcraft/features/orders/widgets/outsource_order_sheet.dart';
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
  final _localDb = LocalDatabaseService();
  bool _isLoading = false;
  Map<String, dynamic>? _order;
  final _noteController = TextEditingController();
  String? _resolvedMaapUrl;
  String? _resolvedFabricUrl;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _resolveUrls() async {
    if (_order == null) return;
    final maapPath = _order!['maapImageUrl'] as String?;
    final fabricPath = _order!['fabricImageUrl'] as String?;
    final token = await _authService.getToken();
    if (token == null) return;

    if (maapPath != null && maapPath.isNotEmpty) {
      try {
        final encodedPath = Uri.encodeComponent(maapPath);
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/upload/view-url/maap-images/$encodedPath'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _resolvedMaapUrl = data['signedUrl'] as String?;
          });
        }
      } catch (e) {
        developer.log("Error loading maap view url: $e");
      }
    }

    if (fabricPath != null && fabricPath.isNotEmpty) {
      try {
        final encodedPath = Uri.encodeComponent(fabricPath);
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/upload/view-url/maap-images/$encodedPath'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _resolvedFabricUrl = data['signedUrl'] as String?;
          });
        }
      } catch (e) {
        developer.log("Error loading fabric view url: $e");
      }
    }
  }

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
    // 1. Try loading from local database first for instant load
    try {
      final localOrder = await _localDb.getRecordById('orders', orderId);
      if (localOrder != null) {
        setState(() {
          _order = _mapSqliteOrderToBackend(localOrder);
        });
      }
    } catch (e) {
      developer.log("Error loading local order details: $e");
    }

    setState(() => _isLoading = _order == null);
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
        await _resolveUrls();
      } else {
        if (_order == null) {
          throw Exception('Failed to load order details (Status: ${response.statusCode}, Body: ${response.body})');
        }
      }
    } catch (e) {
      developer.log("Error loading order details from server: $e");
      if (_order == null && mounted) {
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

    if (newStatus == 'Delivered') {
      final totalAmount = (_order!['payment'] is Map
              ? (_order!['payment']['totalAmount'] as num?)?.toDouble()
              : null) ??
          (_order!['price'] as num?)?.toDouble() ??
          (_order!['total_amount'] as num?)?.toDouble() ??
          0.0;
      final paidAmount = (_order!['payment'] is Map
              ? (_order!['payment']['paidAmount'] as num?)?.toDouble()
              : null) ??
          (_order!['advancePaid'] as num?)?.toDouble() ??
          (_order!['advance_amount'] as num?)?.toDouble() ??
          0.0;
      final balance = (totalAmount - paidAmount).clamp(0.0, double.infinity);

      if (balance > 0) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Deliver with Unpaid Balance?'),
            content: Text(
              'This order has an outstanding balance of ₹${balance.toStringAsFixed(2)}.\n\nDo you want to confirm delivery and keep this balance in Khata (Udhar)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warmAmber,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm Delivery'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    if (!mounted) return;
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
        // Also update local SQLite database status
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        try {
          await _localDb.updateRecord('orders', orderId, {
            'status': newStatus,
            'updated_at': nowMs,
          });
        } catch (localDbErr) {
          developer.log('Local status update sync note: $localDbErr');
        }

        if (newStatus == 'Delivered' || newStatus == 'Cancelled') {
          NotificationService().cancelOrderDueReminders(orderId.toString());
        }

        final isJobFromOtherShop = _isPartnerJobFromOtherShop;
        final notificationMsg = (isJobFromOtherShop && (newStatus == 'Ready' || newStatus == 'Delivered'))
            ? 'Status updated to $newStatus! Main tailor notified via push notification.'
            : 'Status updated to $newStatus';

        messenger.showSnackBar(
          SnackBar(content: Text(notificationMsg), backgroundColor: AppTheme.trustGreen),
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
    final orderId = (_order!['_id'] ?? _order!['id'] ?? '').toString();
    final customerName = _order!['customer_name'] ?? _order!['customer']?['name'] ?? 'Customer';
    final total = (_order!['total_amount'] as num?)?.toDouble() ?? (_order!['price'] as num?)?.toDouble() ?? 0.0;
    final advance = (_order!['advance_amount'] as num?)?.toDouble() ?? 0.0;
    final balance = (total - advance).clamp(0.0, double.infinity);

    final result = await showModalBottomSheet<PaymentResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RecordPaymentSheet(
        customerName: customerName.toString(),
        balance: balance,
      ),
    );

    if (result == null || result.amount <= 0) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        http.post(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'amount': result.amount,
            'paymentType': result.method,
          }),
        );
      }

      try {
        final localOrder = await _localDb.getRecordById('orders', orderId);
        if (localOrder != null) {
          final prevAdvance = (localOrder['advance_amount'] as num?)?.toDouble() ?? 0.0;
          await _localDb.updateRecord('orders', orderId, {
            'advance_amount': prevAdvance + result.amount,
            'payment_method': result.method,
            'sync_status': 3,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (localErr) {
        developer.log('Local payment sync note: $localErr');
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Payment of ${CurrencyUtils.formatINR(result.amount)} recorded!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
        _loadOrderDetails(orderId);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error recording payment: $e'), backgroundColor: AppTheme.alertRed),
        );
      }
    }
  }

  Future<void> _editOrder() async {
    if (_order == null) return;

    final priceController = TextEditingController(text: _order!['price']?.toString() ?? '0');
    DateTime dueDate = _order!['deliveryDate'] != null ? DateTime.parse(_order!['deliveryDate']) : DateTime.now();

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Order Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Price
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Total Price (₹)'),
                  ),
                  const SizedBox(height: 12),

                  // Due Date Selector
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Delivery Date', style: TextStyle(color: AppTheme.darkGrey, fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMMM yyyy (EEEE)').format(dueDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, color: AppTheme.brandPurple),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          dueDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandPurple),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (success != true) {
      priceController.dispose();
      return;
    }

    final price = double.tryParse(priceController.text) ?? 0.0;
    priceController.dispose();
    final orderId = _order!['_id'] ?? _order!['id'];

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'price': price,
          'deliveryDate': dueDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Order updated successfully'), backgroundColor: AppTheme.trustGreen),
        );
        _loadOrderDetails(orderId);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to update order');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error updating order: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteOrder() async {
    if (_order == null) return;
    final orderId = _order!['_id'] ?? _order!['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this order? This action cannot be undone.', style: TextStyle(color: AppTheme.darkGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _localDb.deleteOrder(orderId);
        messenger.showSnackBar(
          const SnackBar(content: Text('Order deleted successfully'), backgroundColor: AppTheme.trustGreen),
        );
        nav.pop(); // Go back to orders list
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete order');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error deleting order: $e'), backgroundColor: AppTheme.alertRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendWhatsAppStatusUpdate() async {
    if (_order == null) return;
    final String customerName = _order!['customerName'] ?? 'Customer';
    final String customerPhone = _order!['customerPhone'] ?? _order!['customer']?['phone'] ?? '';
    final String orderId = _order!['_id'] ?? _order!['id'] ?? '';
    final String status = _order!['status'] ?? 'pending';

    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number linked to this customer'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    String message = "Hello $customerName, here is an update on your tailoring order #$orderId:\n\n"
        "Status: *${status.toUpperCase()}*\n\n"
        "We will notify you of further progress. Thank you!";

    if (status.toLowerCase() == 'trial ready') {
      message = "Hello $customerName, friendly update: your tailoring order #$orderId is *READY FOR TRIAL*. Please drop by when convenient!\n\n"
          "Thank you!";
    } else if (status.toLowerCase() == 'ready' || status.toLowerCase() == 'ready to deliver') {
      message = "Hello $customerName, great news! Your tailoring order #$orderId is *READY FOR PICKUP*.\n\n"
          "Thank you!";
    }

    final String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final String targetPhone = cleanPhone.startsWith('91') || cleanPhone.length != 10 ? cleanPhone : '91$cleanPhone';

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

  void _openInvoiceShare() {
    if (_order == null) return;
    final orderId = _order!['_id'] ?? _order!['id'] ?? '';
    Navigator.pushNamed(context, '/invoice_details', arguments: orderId);
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _editOrder,
                  tooltip: 'Edit Order',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed),
                  onPressed: _deleteOrder,
                  tooltip: 'Delete Order',
                ),
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
                            if (_isOutsourcedToPartner)
                              _infoRow(
                                'Outsourced To',
                                '${_order!['delegatedToShopName'] ?? _order!['delegated_to_shop_name'] ?? 'Partner'} (${(_order!['delegationStatus'] ?? _order!['delegation_status'] ?? 'assigned').toString().toUpperCase()})',
                              ),
                            if (_isPartnerJobFromOtherShop)
                              _infoRow(
                                'Job from Shop',
                                '${_order!['originShopName'] ?? _order!['origin_shop_name'] ?? 'External Shop'}',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Outsource / Partner Tailor Action & Status Card
                      _buildOutsourcingSection(theme),
                      const SizedBox(height: 16),

                      // Interactive Production Stage Stepper
                      _buildProductionStepper(theme),
                      const SizedBox(height: 16),

                      // Quick Action Bar (Call, WhatsApp, Invoice)
                      _buildQuickActionBar(theme),
                      const SizedBox(height: 16),

                      // Measurements details if present
                      if (_order!['measurements'] != null) ...[
                        Text('Measurements Snapshot', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
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

                      // Captured Images Section
                      if ((_resolvedMaapUrl != null && _resolvedMaapUrl!.isNotEmpty) ||
                          (_resolvedFabricUrl != null && _resolvedFabricUrl!.isNotEmpty)) ...[
                        Text('Captured Photos', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
                        const SizedBox(height: 8),
                        NeoCard(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_resolvedMaapUrl != null && _resolvedMaapUrl!.isNotEmpty) ...[
                                  _buildPhotoCard('Sample (Namuna)', _resolvedMaapUrl!),
                                  const SizedBox(width: 16),
                                ],
                                if (_resolvedFabricUrl != null && _resolvedFabricUrl!.isNotEmpty)
                                  _buildPhotoCard('Fabric Specimen', _resolvedFabricUrl!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Invoices & Payments summary
                      Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
                      const SizedBox(height: 8),
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Cost', style: TextStyle(color: AppTheme.darkGrey)),
                                Text('₹${_order!['price'] ?? 0}', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Text('Order Notes Timeline', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 16)),
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
                                              Text(note['text'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface)),
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
                                    style: TextStyle(color: theme.colorScheme.onSurface),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      bottomNavigationBar: _order == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildPrimaryNextStageButton(theme),
              ),
            ),
    );
  }

  Widget _buildPrimaryNextStageButton(ThemeData theme) {
    final currentStatus = (_order!['status'] ?? 'Incoming').toString();
    final stages = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered'];
    final currentIndex = stages.indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());
    final nextStage = (currentIndex >= 0 && currentIndex < stages.length - 1) ? stages[currentIndex + 1] : null;

    if (nextStage == null) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.trustGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.trustGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.trustGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              currentStatus.toLowerCase() == 'delivered' ? 'Order Delivered & Complete' : 'Order $currentStatus',
              style: const TextStyle(
                color: AppTheme.trustGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final isReadyNext = nextStage == 'Ready';
    final isDeliveredNext = nextStage == 'Delivered';

    return PrimaryNextAction(
      label: isDeliveredNext
          ? 'Mark Delivered'
          : isReadyNext
              ? 'Mark Ready for Pickup'
              : 'Move to $nextStage',
      icon: isDeliveredNext
          ? Icons.task_alt
          : isReadyNext
              ? Icons.check_circle_outline
              : Icons.arrow_forward_rounded,
      backgroundColor: isDeliveredNext ? AppTheme.trustGreen : AppTheme.brandPurple,
      isLoading: _isLoading,
      onPressed: () => _updateStatus(nextStage),
    );
  }

  Widget _buildProductionStepper(ThemeData theme) {
    final currentStatus = (_order!['status'] ?? 'Incoming').toString();
    final stages = ['Incoming', 'Measuring', 'Cutting', 'Stitching', 'Checking', 'Ready', 'Delivered'];
    final currentIndex = stages.indexWhere(
      (s) => s.toLowerCase() == currentStatus.toLowerCase(),
    );

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Production Progress',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tap stage to update',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkGrey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stages.asMap().entries.map((entry) {
                final index = entry.key;
                final stage = entry.value;
                final isCurrent = currentIndex == index || (currentIndex == -1 && index == 0);
                final isPassed = currentIndex >= 0 && index < currentIndex;

                return GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.cardTheme.color,
                        title: Text('Advance to $stage?', style: TextStyle(color: theme.colorScheme.onSurface)),
                        content: Text('Update order status to $stage?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _updateStatus(stage);
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.brandPurple
                              : isPassed
                                  ? AppTheme.trustGreen.withValues(alpha: 0.15)
                                  : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? AppTheme.brandPurple
                                : isPassed
                                    ? AppTheme.trustGreen
                                    : AppTheme.darkGrey.withValues(alpha: 0.3),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPassed)
                              const Icon(Icons.check, size: 14, color: AppTheme.trustGreen)
                            else if (isCurrent)
                              const Icon(Icons.radio_button_checked, size: 12, color: Colors.white),
                            if (isPassed || isCurrent) const SizedBox(width: 4),
                            Text(
                              stage,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent
                                    ? Colors.white
                                    : isPassed
                                        ? AppTheme.trustGreen
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < stages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: isPassed ? AppTheme.trustGreen : AppTheme.darkGrey.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isOutsourcedToPartner {
    final name = _order?['delegatedToShopName'] ?? _order?['delegated_to_shop_name'];
    final status = _order?['delegationStatus'] ?? _order?['delegation_status'];
    return name != null && name.toString().trim().isNotEmpty && status != 'revoked';
  }

  bool get _isPartnerJobFromOtherShop {
    final origin = _order?['originShopName'] ?? _order?['origin_shop_name'];
    return origin != null && origin.toString().trim().isNotEmpty;
  }

  void _openOutsourceSheet() {
    if (_order == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OutsourceOrderSheet(
        order: _order!,
        onUpdated: (updatedOrder) {
          setState(() {
            _order = {
              ..._order!,
              ...updatedOrder,
            };
          });
          final id = _order!['_id'] ?? _order!['id'];
          if (id != null) {
            _loadOrderDetails(id.toString());
          }
        },
      ),
    );
  }

  Widget _buildOutsourcingSection(ThemeData theme) {
    if (_isPartnerJobFromOtherShop) {
      final originShop = _order!['originShopName'] ?? _order!['origin_shop_name'] ?? 'Another Tailor';
      final originPhone = _order!['originPhone'] ?? _order!['origin_phone'] ?? '';
      final notes = _order!['delegatedNotes'] ?? _order!['delegated_notes'] ?? '';

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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: AppTheme.brandPurple, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job from Another Shop',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        originShop.toString(),
                        style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (originPhone.toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppTheme.trustGreen, size: 20),
                    tooltip: 'Call Originating Tailor',
                    onPressed: () async {
                      final uri = Uri.parse('tel:$originPhone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
              ],
            ),
            if (notes.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Instructions: $notes',
                  style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.trustGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Marking this order Ready will automatically notify $originShop via push notification.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.trustGreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isOutsourcedToPartner) {
      final partnerName = _order!['delegatedToShopName'] ?? _order!['delegated_to_shop_name'] ?? 'Partner Tailor';
      final partnerPhone = _order!['delegatedToPhone'] ?? _order!['delegated_to_phone'] ?? '';
      final delStatus = (_order!['delegationStatus'] ?? _order!['delegation_status'] ?? 'assigned').toString().toUpperCase();
      final notes = _order!['delegatedNotes'] ?? _order!['delegated_notes'] ?? '';

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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.handshake_outlined, color: AppTheme.brandPurple, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outsourced to Partner Tailor',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        partnerName.toString(),
                        style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (delStatus == 'COMPLETED' ? AppTheme.trustGreen : AppTheme.brandPurple).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    delStatus,
                    style: TextStyle(
                      color: delStatus == 'COMPLETED' ? AppTheme.trustGreen : AppTheme.brandPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (notes.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Instructions: $notes',
                  style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (partnerPhone.toString().isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call Partner', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final uri = Uri.parse('tel:$partnerPhone');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ),
                if (partnerPhone.toString().isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Manage / Recall', style: TextStyle(fontSize: 12)),
                    onPressed: _openOutsourceSheet,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default: Not outsourced yet
    return NeoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.brandPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handshake_outlined, color: AppTheme.brandPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outsource Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Assign this order as a job to another tailor',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _openOutsourceSheet,
            child: const Text('Outsource', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(ThemeData theme) {
    final customerPhone = (_order!['customerPhone'] ?? _order!['customer']?['phone'] ?? '').toString();
    final hasPhone = customerPhone.isNotEmpty;

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasPhone) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:$customerPhone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    icon: const Icon(Icons.phone, size: 16, color: AppTheme.brandPurple),
                    label: const Text(
                      'Call',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                  onPressed: _sendWhatsAppStatusUpdate,
                  icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                  onPressed: _openInvoiceShare,
                  icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                  label: const Text(
                    'Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
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

  List<Widget> _buildMeasurementChips(Map<String, dynamic> measurements) {
    final chips = <Widget>[];

    void processMap(Map<dynamic, dynamic> map, {String prefix = ''}) {
      map.forEach((key, val) {
        if (val is Map) {
          processMap(val, prefix: '${key.toString().toUpperCase()} ');
        } else if (val != null && val is num && val > 0) {
          chips.add(
            Chip(
              backgroundColor: AppTheme.lightGrey,
              label: Text(
                '$prefix${key.toString().toUpperCase()}: $val"',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          );
        }
      });
    }

    processMap(measurements);

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

  Widget _buildPhotoCard(String title, String url) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 180,
              height: 180,
              color: Colors.white.withValues(alpha: 0.05),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, color: AppTheme.alertRed, size: 36),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _mapSqliteOrderToBackend(Map<String, dynamic> m) {
    final Map<String, dynamic> data = {};
    data['_id'] = m['id'];
    data['id'] = m['id'];
    data['customerName'] = m['customer_name'] ?? 'Walk-in Customer';
    
    // Resolve customer object
    data['customer'] = {
      '_id': m['customer_id'] ?? '',
      'id': m['customer_id'] ?? '',
      'name': m['customer_name'] ?? 'Walk-in Customer',
    };
    
    // Status
    data['status'] = m['status'] ?? 'Incoming';
    
    // Price
    data['price'] = (m['total_amount'] as num?)?.toDouble() ?? 0.0;
    
    // Dates
    if (m['order_date'] != null) {
      data['date'] = DateTime.fromMillisecondsSinceEpoch(m['order_date'] as int).toUtc().toIso8601String();
    }
    if (m['due_date'] != null) {
      data['deliveryDate'] = DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int).toUtc().toIso8601String();
    }
    
    // Apparel/Garment Type
    final itemTypesStr = m['item_types'] as String?;
    final itemTypesList = itemTypesStr != null ? itemTypesStr.split(',').where((e) => e.isNotEmpty).toList() : [];
    data['garmentType'] = itemTypesList.isNotEmpty ? itemTypesList.first : 'Custom Order';
    data['apparelType'] = data['garmentType'];
    
    // Fabric
    data['fabric'] = m['description'] ?? '';
    
    // Fabric image
    data['fabricImageUrl'] = m['fabric_photo_url'] ?? '';
    
    // Payment mock
    data['payment'] = {
      'paidAmount': (m['advance_amount'] as num?)?.toDouble() ?? 0.0,
      'balanceAmount': ((m['total_amount'] as num?)?.toDouble() ?? 0.0) - ((m['advance_amount'] as num?)?.toDouble() ?? 0.0),
    };
    
    // Default empty lists for relation population
    data['assignedKarigar'] = null;
    data['assignedMachine'] = null;
    data['asterInventoryItem'] = null;
    data['notes'] = [];

    // Outsourcing / Delegation fields
    data['delegatedToShopId'] = m['delegated_to_shop_id'];
    data['delegatedToShopName'] = m['delegated_to_shop_name'];
    data['delegatedToPhone'] = m['delegated_to_phone'];
    data['delegationStatus'] = m['delegation_status'];
    data['delegatedNotes'] = m['delegated_notes'];
    data['originShopName'] = m['origin_shop_name'];
    data['originPhone'] = m['origin_phone'];
    
    // Try to parse style attributes
    if (m['style_attributes_json'] != null) {
      try {
        data['styleAttributes'] = jsonDecode(m['style_attributes_json']);
      } catch (e) {
        data['styleAttributes'] = {};
      }
    }
    
    return data;
  }
}
