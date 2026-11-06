import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';

class OrderListScreen extends StatefulWidget {
  final String title;
  final String statusFilter;

  final bool isTab;

  const OrderListScreen({
    super.key,
    this.title = 'Orders',
    this.statusFilter = 'all',
    this.isTab = false,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatusTab = 'All';

  @override
  void initState() {
    super.initState();
    _selectedStatusTab = _getInitialStatusTab(widget.statusFilter);
    _loadOrders();
  }

  String _getInitialStatusTab(String filter) {
    if (filter.isEmpty || filter.toLowerCase() == 'all') return 'All';
    if (filter.toLowerCase() == 'pending') return 'Pending';
    if (filter.toLowerCase() == 'due_today') return 'Due Today';
    if (filter.toLowerCase() == 'late') return 'Late';
    if (filter.toLowerCase() == 'unpaid') return 'Unpaid';
    final match =
        [
          'All',
          'Due Today',
          'Late',
          'Pending',
          'Unpaid',
          'Incoming',
          'Measuring',
          'Cutting',
          'Stitching',
          'Checking',
          'Ready',
          'Delivered',
          'Cancelled',
        ].firstWhere(
          (element) => element.toLowerCase() == filter.toLowerCase(),
          orElse: () => 'All',
        );
    return match;
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      var list = await _localDb.getAllOrders();

      if (list.isEmpty) {
        final token = await AuthService().getToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse('${AuthService.baseUrl}/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode == 200) {
            final List<dynamic> remoteData = json.decode(response.body);
            for (final rawRecord in remoteData) {
              final Map<String, dynamic> remoteRecord =
                  Map<String, dynamic>.from(rawRecord);
              final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
              if (id.isEmpty) continue;

              final Map<String, dynamic> sqliteRecord = {
                'id': id,
                'customer_id': remoteRecord['customer'] is Map
                    ? remoteRecord['customer']['_id']
                    : remoteRecord['customer'] ?? '',
                'customer_name':
                    remoteRecord['customerName'] ?? 'Walk-in Customer',
                'order_date': remoteRecord['date'] != null
                    ? DateTime.parse(
                        remoteRecord['date'].toString(),
                      ).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
                'due_date': remoteRecord['deliveryDate'] != null
                    ? DateTime.parse(
                        remoteRecord['deliveryDate'].toString(),
                      ).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
                'status': remoteRecord['status'] ?? 'pending',
                'total_amount':
                    (remoteRecord['price'] as num?)?.toDouble() ?? 0.0,
                'description': remoteRecord['fabric'] ?? '',
                'sync_status': 0,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              };
              final hasPending = await _localDb.hasPendingMutation('orders', id);
              if (!hasPending) {
                await _localDb.insertRecord('orders', sqliteRecord, fromRepository: true);
              }
            }
            list = await _localDb.getAllOrders();
          }
        }
      }

      setState(() {
        _allOrders = list;
        _applyFilters();
      });
    } catch (e) {
      debugPrint("Error loading orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = _allOrders;

    // 1. Status Filter
    if (_selectedStatusTab == 'Due Today') {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      result = result.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (status == 'delivered' || status == 'cancelled') return false;
        final due = _parseDate(o['due_date']);
        return due != null &&
            due.year == startOfToday.year &&
            due.month == startOfToday.month &&
            due.day == startOfToday.day;
      }).toList();
    } else if (_selectedStatusTab == 'Late') {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      result = result.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (status == 'delivered' || status == 'cancelled') return false;
        final due = _parseDate(o['due_date']);
        return due != null && due.isBefore(startOfToday);
      }).toList();
    } else if (_selectedStatusTab == 'Unpaid') {
      result = result.where((o) {
        final total = (o['total_amount'] as num?)?.toDouble() ??
            (o['price'] as num?)?.toDouble() ??
            0.0;
        final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
        return (total - advance) > 0;
      }).toList();
    } else if (_selectedStatusTab == 'Pending') {
      result = result.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        return status != 'delivered' && status != 'cancelled';
      }).toList();
    } else if (_selectedStatusTab != 'All') {
      result = result.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        return status == _selectedStatusTab.toLowerCase();
      }).toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((o) {
        final name = (o['customer_name'] ?? '').toString().toLowerCase();
        final id = (o['id'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            id.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredOrders = result;
    });
  }

  DateTime? _parseDate(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: widget.title,
        automaticallyImplyLeading: !widget.isTab,
      ),
      body: Column(
        children: [
          // Sticky Search bar and Tabs Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _applyFilters();
              },
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Search Orders...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Status tabs row
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  [
                    'All',
                    'Due Today',
                    'Late',
                    'Pending',
                    'Ready',
                    'Unpaid',
                    'Incoming',
                    'Measuring',
                    'Cutting',
                    'Stitching',
                    'Checking',
                    'Delivered',
                    'Cancelled',
                  ].map((tab) {
                    final isSelected = _selectedStatusTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatusTab = tab;
                          });
                          _applyFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brandPurple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            tab == 'All' ? context.loc.all : tab,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.darkGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppTheme.brandPurple.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty && _selectedStatusTab == 'All'
                                ? 'No orders yet'
                                : context.loc.no_orders_found,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isEmpty && _selectedStatusTab == 'All'
                                ? 'Create your first order to start tracking work.'
                                : 'Try clearing the search or status filter.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_searchQuery.isEmpty &&
                              _selectedStatusTab == 'All')
                            FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/create_order_customer',
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create new order'),
                            )
                          else
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedStatusTab = 'All';
                                });
                                _applyFilters();
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh:
                        _loadOrders, // This calls your existing loading logic
                    color: AppTheme.brandPurple,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 0, 16, widget.isTab ? 96 : 24),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final String idStr =
                            order['id']
                                ?.toString()
                                .split('-')
                                .first
                                .toUpperCase() ??
                            '';
                        final String nameStr =
                            order['customer_name'] ?? 'Walk-in Customer';
                        final double amount =
                            (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                        final double paid =
                            (order['advance_amount'] as num?)?.toDouble() ??
                            0.0;
                        final double balance = (amount - paid).clamp(
                          0,
                          double.infinity,
                        );
                        final String status = order['status'] ?? 'pending';
                        final dueDate = _parseDate(order['due_date']);
                        final dueText = dueDate == null
                            ? 'No due date'
                            : 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
                        final isPendingSync = (order['sync_status'] ?? 0) != 0;

                        return NeoCard(
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              '/order_details',
                              arguments: order['id'] ?? '',
                            );
                            _loadOrders();
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(4),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.brandPurple.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                idStr.isNotEmpty
                                    ? idStr.substring(
                                        0,
                                        idStr.length > 3 ? 3 : idStr.length,
                                      )
                                    : 'ORD',
                                style: const TextStyle(
                                  color: AppTheme.brandPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              nameStr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$dueText • Balance ${CurrencyUtils.formatINR(balance, showDecimals: false)}',
                                ),
                                if (isPendingSync) ...[
                                  const SizedBox(height: 3),
                                  const PendingChip(compact: true),
                                ],
                              ],
                            ),
                            trailing: StatusBadge(
                              status: status,
                              compact: true,
                            ),
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
}
