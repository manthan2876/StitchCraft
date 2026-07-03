import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';

class OrderListScreen extends StatefulWidget {
  final String title;
  final String statusFilter; // 'pending', 'completed', 'all'

  const OrderListScreen({
    super.key,
    this.title = 'Orders',
    this.statusFilter = 'all',
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final list = await _localDb.getAllOrders();
      setState(() {
        if (widget.statusFilter == 'pending') {
          _orders = list.where((o) => o['status']?.toString().toLowerCase() != 'completed' && o['status']?.toString().toLowerCase() != 'delivered').toList();
        } else if (widget.statusFilter == 'completed') {
          _orders = list.where((o) => o['status']?.toString().toLowerCase() == 'completed' || o['status']?.toString().toLowerCase() == 'delivered').toList();
        } else {
          _orders = list;
        }
      });
    } catch (e) {
      debugPrint("Error loading orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Text(
                    'No orders found.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final String idStr = order['id']?.toString().split('-').first.toUpperCase() ?? '';
                    final String nameStr = order['customer_name'] ?? 'Walk-in Customer';
                    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                    final String status = order['status'] ?? 'pending';

                    return NeoCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(4),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                          child: Text(
                            idStr.isNotEmpty ? idStr.substring(0, idStr.length > 3 ? 3 : idStr.length) : 'ORD',
                            style: const TextStyle(color: AppTheme.brandPurple, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(nameStr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text('₹$amount • Status: $status'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('incoming')) {
      return AppTheme.safetyOrange;
    } else if (s.contains('progress') || s.contains('stitching')) {
      return AppTheme.brandPurple;
    } else if (s.contains('ready') || s.contains('completed')) {
      return AppTheme.trustGreen;
    } else if (s.contains('delivered')) {
      return AppTheme.navyBlue;
    }
    return AppTheme.darkGrey;
  }
}
