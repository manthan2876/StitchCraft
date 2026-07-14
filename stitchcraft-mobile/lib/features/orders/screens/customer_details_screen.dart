import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _customerData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customerData == null) {
      final customerId = ModalRoute.of(context)!.settings.arguments as String;
      _loadCustomerDetails(customerId);
    }
  }

  Future<void> _loadCustomerDetails(String customerId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/customers/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _customerData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load customer profile');
      }
    } catch (e) {
      developer.log("Error loading customer profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customer profile: $e'), backgroundColor: AppTheme.alertRed),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _customerData != null ? _customerData!['name'] ?? 'Customer' : 'Loading...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading && _customerData == null
          ? const Center(child: CircularProgressIndicator())
          : _customerData == null
              ? const Center(child: Text('Failed to load customer profile', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact info block
                      NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                                  child: Text(
                                    title.isNotEmpty ? title[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: AppTheme.brandPurple, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Phone: ${_customerData!['phone'] ?? 'N/A'}',
                                        style: const TextStyle(color: AppTheme.darkGrey),
                                      ),
                                      if (_customerData!['email'] != null && _customerData!['email'].toString().isNotEmpty)
                                        Text(
                                          'Email: ${_customerData!['email']}',
                                          style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Measurements tab block
                      const Text(
                        'Stored Fitting Measurements',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorColor: AppTheme.brandPurple,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppTheme.darkGrey,
                              tabs: const [
                                Tab(text: 'Shirt (શર્ટ / कुर्ता)'),
                                Tab(text: 'Pant (પેન્ટ / सलवार)'),
                              ],
                            ),
                            SizedBox(
                              height: 220,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildShirtTab(_customerData!['measurements']?['shirt'] ?? {}),
                                  _buildPantTab(_customerData!['measurements']?['pant'] ?? {}),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Order history list
                      const Text(
                        'Order History',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (_customerData!['orders'] == null || (_customerData!['orders'] as List).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No orders placed by this customer.', style: TextStyle(color: AppTheme.darkGrey))),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_customerData!['orders'] as List).length,
                          itemBuilder: (context, index) {
                            final order = _customerData!['orders'][index];
                            final double amount = (order['price'] as num?)?.toDouble() ?? 0.0;
                            final String status = order['status'] ?? 'Incoming';
                            final String orderId = order['_id'] ?? order['id'];
                            final String dateStr = order['date'] != null
                                ? DateFormat('dd MMM yyyy').format(DateTime.parse(order['date']))
                                : 'N/A';

                            return NeoCard(
                              onTap: () {
                                Navigator.pushNamed(context, '/order_details', arguments: orderId);
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                                  child: const Icon(Icons.content_cut, color: AppTheme.brandPurple, size: 18),
                                ),
                                title: Text(order['garmentType'] ?? 'Custom Order', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text('₹$amount • Date: $dateStr'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildShirtTab(Map<String, dynamic> shirt) {
    if (shirt.isEmpty) {
      return const Center(child: Text('No shirt measurements saved', style: TextStyle(color: AppTheme.darkGrey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _mItem('Neck', shirt['neck']),
            _mItem('Chest', shirt['chest']),
            _mItem('Waist', shirt['waist']),
            _mItem('Hips', shirt['hips']),
            _mItem('Shoulder', shirt['shoulder']),
            _mItem('Sleeves', shirt['sleeves']),
            _mItem('Length', shirt['length']),
          ],
        ),
        if (shirt['notes'] != null && shirt['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Notes: ${shirt['notes']}', style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildPantTab(Map<String, dynamic> pant) {
    if (pant.isEmpty) {
      return const Center(child: Text('No pant measurements saved', style: TextStyle(color: AppTheme.darkGrey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _mItem('Length', pant['length']),
            _mItem('Waist', pant['waist']),
            _mItem('Hips', pant['hips']),
            _mItem('Inseam', pant['inseam']),
            _mItem('Thigh', pant['thigh']),
            _mItem('Rise', pant['rise']),
            _mItem('Bottom', pant['bottom']),
          ],
        ),
        if (pant['notes'] != null && pant['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Notes: ${pant['notes']}', style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _mItem(String label, dynamic val) {
    final value = (val as num?)?.toDouble() ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value"',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('incoming')) {
      return AppTheme.safetyOrange;
    } else if (s.contains('progress') || s.contains('stitching') || s.contains('cutting') || s.contains('measuring')) {
      return AppTheme.brandPurple;
    } else if (s.contains('ready') || s.contains('completed') || s.contains('checking')) {
      return AppTheme.trustGreen;
    }
    return AppTheme.darkGrey;
  }
}
