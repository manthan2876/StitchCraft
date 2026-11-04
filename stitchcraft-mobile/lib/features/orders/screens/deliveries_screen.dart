import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:http/http.dart' as http;

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final _localDb = LocalDatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  String _filter = 'today'; // 'today', 'late', 'unpaid', 'all'
  List<Map<String, dynamic>> _allReadyOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _localDb.getAllOrders();
      // Orders that are Ready for pickup / delivery
      final readyOrders = orders.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        return status == 'ready';
      }).toList();

      if (mounted) {
        setState(() {
          _allReadyOrders = readyOrders;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> result = _allReadyOrders;

    if (_filter == 'today') {
      result = result.where((o) {
        final due = _parseDate(o['due_date']);
        if (due == null) return true;
        return due.year == todayMidnight.year &&
            due.month == todayMidnight.month &&
            due.day == todayMidnight.day;
      }).toList();
    } else if (_filter == 'late') {
      result = result.where((o) {
        final due = _parseDate(o['due_date']);
        if (due == null) return false;
        return due.isBefore(todayMidnight);
      }).toList();
    } else if (_filter == 'unpaid') {
      result = result.where((o) {
        final total = (o['total_amount'] as num?)?.toDouble() ??
            (o['price'] as num?)?.toDouble() ??
            0.0;
        final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
        return (total - advance) > 0.01;
      }).toList();
    }

    setState(() => _filteredOrders = result);
  }

  DateTime? _parseDate(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<void> _confirmAndDeliver(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final total = (order['total_amount'] as num?)?.toDouble() ??
        (order['price'] as num?)?.toDouble() ??
        0.0;
    final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
    final balance = (total - advance).clamp(0.0, double.infinity);

    if (balance > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warmAmber, size: 28),
              const SizedBox(width: 8),
              Text(context.loc.deliver_unpaid_warning),
            ],
          ),
          content: Text(
            'This order has an outstanding balance of ${CurrencyUtils.formatINR(balance)}.\n\nDelivering this order will keep the balance recorded in Khata (Udhar). Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.trustGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      // 1. Update SQLite
      await _localDb.updateRecord('orders', orderId, {
        'status': 'Delivered',
        'sync_status': 3,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 2. Put to backend if online
      final token = await _authService.getToken();
      if (token != null) {
        http.put(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'status': 'Delivered'}),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as Delivered!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
      _loadDeliveries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally: $e'),
            backgroundColor: AppTheme.warmAmber,
          ),
        );
      }
      _loadDeliveries();
    }
  }

  Future<void> _recordPayment(Map<String, dynamic> order, double balance) async {
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final customerName = order['customer_name']?.toString() ?? 'Customer';
    final ctrl = TextEditingController(text: balance.toStringAsFixed(0));
    String paymentMethod = 'cash';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collect Payment: $customerName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Balance Due: ${CurrencyUtils.formatINR(balance)}',
                style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: paymentMethod == 'cash',
                    onSelected: (val) => setModalState(() => paymentMethod = 'cash'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('UPI / Online'),
                    selected: paymentMethod == 'online',
                    onSelected: (val) => setModalState(() => paymentMethod = 'online'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.trustGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    if (amt <= 0) return;
                    Navigator.pop(ctx);

                    final currAdv = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
                    await _localDb.updateRecord('orders', orderId, {
                      'advance_amount': currAdv + amt,
                      'sync_status': 3,
                      'updated_at': DateTime.now().millisecondsSinceEpoch,
                    });

                    final token = await _authService.getToken();
                    if (token != null) {
                      http.post(
                        Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                        body: json.encode({'amount': amt, 'paymentType': paymentMethod}),
                      );
                    }
                    _loadDeliveries();
                  },
                  child: const Text('Save Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: context.loc.deliver_today),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('today', context.loc.today),
                  const SizedBox(width: 8),
                  _filterChip('late', context.loc.late),
                  const SizedBox(width: 8),
                  _filterChip('unpaid', context.loc.unpaid),
                  const SizedBox(width: 8),
                  _filterChip('all', 'All Ready'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _filteredOrders.isEmpty
                    ? EmptyStateView(
                        icon: Icons.local_shipping_outlined,
                        title: 'No pending deliveries',
                        subtitle: 'All orders matching this filter have been processed.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDeliveries,
                        color: AppTheme.brandPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final id = (order['id'] ?? order['_id'] ?? '').toString();
                            final customer = (order['customer_name'] ?? 'Customer').toString();
                            final garment = (order['garment_type'] ?? 'Garment').toString();
                            final total = (order['total_amount'] as num?)?.toDouble() ??
                                (order['price'] as num?)?.toDouble() ??
                                0.0;
                            final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
                            final balance = (total - advance).clamp(0.0, double.infinity);
                            final dueDate = _parseDate(order['due_date']);
                            final dueStr = dueDate == null ? '' : 'Due: ${dueDate.day}/${dueDate.month}';

                            return NeoCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$customer • $garment',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const StatusBadge(status: 'Ready', compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #$id ${dueStr.isNotEmpty ? '• $dueStr' : ''}',
                                        style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                                      ),
                                      Text(
                                        balance > 0
                                            ? 'Balance: ${CurrencyUtils.formatINR(balance)}'
                                            : 'Fully Paid',
                                        style: TextStyle(
                                          color: balance > 0 ? AppTheme.alertRed : AppTheme.trustGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      if (balance > 0) ...[
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 46),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () => _recordPayment(order, balance),
                                            child: const Text('Record Payment'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.trustGreen,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 46),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _confirmAndDeliver(order),
                                          icon: const Icon(Icons.task_alt, size: 18),
                                          label: const Text(
                                            'Deliver',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _filter = key);
          _applyFilter();
        }
      },
      selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brandPurple : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

