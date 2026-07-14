import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/features/dashboard/widgets/drawer_menu.dart';

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
    if (filter == 'pending') return 'Pending';
    if (filter == 'completed') return 'Completed';
    return 'All';
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
              final Map<String, dynamic> remoteRecord = Map<String, dynamic>.from(rawRecord);
              final String id = remoteRecord['_id'] ?? remoteRecord['id'] ?? '';
              if (id.isEmpty) continue;

              final Map<String, dynamic> sqliteRecord = {
                'id': id,
                'customer_id': remoteRecord['customer'] is Map ? remoteRecord['customer']['_id'] : remoteRecord['customer'] ?? '',
                'customer_name': remoteRecord['customerName'] ?? 'Walk-in Customer',
                'order_date': remoteRecord['date'] != null 
                    ? DateTime.parse(remoteRecord['date'].toString()).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
                'due_date': remoteRecord['deliveryDate'] != null 
                    ? DateTime.parse(remoteRecord['deliveryDate'].toString()).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
                'status': remoteRecord['status'] ?? 'pending',
                'total_amount': (remoteRecord['price'] as num?)?.toDouble() ?? 0.0,
                'description': remoteRecord['fabric'] ?? '',
                'sync_status': 0,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              };
              await _localDb.insertRecord('orders', sqliteRecord);
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
    if (_selectedStatusTab != 'All') {
      result = result.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (_selectedStatusTab == 'Pending') {
          return status != 'completed' && status != 'delivered';
        } else if (_selectedStatusTab == 'Completed') {
          return status == 'completed';
        } else if (_selectedStatusTab == 'Delivered') {
          return status == 'delivered';
        }
        return true;
      }).toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((o) {
        final name = (o['customer_name'] ?? '').toString().toLowerCase();
        final id = (o['id'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || id.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredOrders = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: widget.title, showDrawerButton: !widget.isTab),
      drawer: widget.isTab ? null : const DrawerMenu(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['All', 'Pending', 'Completed', 'Delivered'].map((tab) {
                final isSelected = _selectedStatusTab == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatusTab = tab;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.brandPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.darkGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                        child: Text(
                          'No orders matching filters.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final String idStr = order['id']?.toString().split('-').first.toUpperCase() ?? '';
                          final String nameStr = order['customer_name'] ?? 'Walk-in Customer';
                          final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                          final String status = order['status'] ?? 'pending';

                          return NeoCard(
                            onTap: () async {
                              await Navigator.pushNamed(context, '/order_details', arguments: order['id'] ?? '');
                              _loadOrders();
                            },
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
          ),
        ],
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
