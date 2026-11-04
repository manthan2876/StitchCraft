import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/utils/phone_utils.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();
  bool _isLoading = false;
  Map<String, dynamic>? _customerData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    Map<String, dynamic>? profile;

    // 1. Attempt loading from backend REST API
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/customers/$customerId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            profile = decoded;
          }
        }
      }
    } catch (e) {
      developer.log("Remote customer fetch note: $e");
    }

    // 2. Offline / local fallback if remote profile is null
    if (profile == null) {
      try {
        final localCust = await _localDb.getRecordById('customers', customerId);
        if (localCust != null) {
          profile = Map<String, dynamic>.from(localCust);
        } else {
          // Look up by clean phone if customerId is a phone number
          final allCust = await _localDb.getCustomers();
          final cleanArg = PhoneUtils.sanitizePhoneNumber(customerId);
          for (final c in allCust) {
            if (PhoneUtils.sanitizePhoneNumber(c['phone'] ?? '') == cleanArg) {
              profile = Map<String, dynamic>.from(c);
              break;
            }
          }
        }
      } catch (localErr) {
        developer.log("Local customer fetch note: $localErr");
      }
    }

    if (profile == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load customer profile'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
      return;
    }

    // 3. Robust Order Retrieval (combining remote orders + local SQLite orders)
    final existingOrders = List<dynamic>.from(profile['orders'] ?? []);
    final Set<String> existingOrderIds = existingOrders
        .map((o) => (o['_id'] ?? o['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    try {
      final localOrders = await _localDb.getAllOrders();
      final cleanCustPhone =
          PhoneUtils.sanitizePhoneNumber(profile['phone'] ?? '');
      final custName = (profile['name'] ?? '').toString().trim().toLowerCase();
      final targetCustId = (profile['_id'] ?? profile['id'] ?? customerId).toString();

      for (final lo in localOrders) {
        final loId = (lo['id'] ?? lo['_id'] ?? '').toString();
        if (loId.isNotEmpty && existingOrderIds.contains(loId)) continue;

        final loCustId = (lo['customer_id'] ?? '').toString();
        final loPhone = PhoneUtils.sanitizePhoneNumber(
          (lo['phone'] ?? lo['customer_phone'] ?? '').toString(),
        );
        final loName =
            (lo['customer_name'] ?? '').toString().trim().toLowerCase();

        final bool matches = (loCustId.isNotEmpty && loCustId == targetCustId) ||
            (cleanCustPhone.isNotEmpty && loPhone.isNotEmpty && loPhone == cleanCustPhone) ||
            (custName.isNotEmpty && loName.isNotEmpty && loName == custName);

        if (matches) {
          existingOrders.add({
            '_id': loId,
            'id': loId,
            'price': (lo['total_amount'] as num?)?.toDouble() ?? 0.0,
            'total_amount': (lo['total_amount'] as num?)?.toDouble() ?? 0.0,
            'advance_amount': (lo['advance_amount'] as num?)?.toDouble() ?? 0.0,
            'status': lo['status'] ?? 'Incoming',
            'garmentType': lo['item_types'] ?? lo['description'] ?? 'Custom Order',
            'apparelType': lo['item_types'] ?? lo['description'] ?? 'Custom Order',
            'date': lo['order_date'] != null
                ? DateTime.fromMillisecondsSinceEpoch(lo['order_date']).toIso8601String()
                : null,
            'order_date': lo['order_date'],
          });
          if (loId.isNotEmpty) existingOrderIds.add(loId);
        }
      }
    } catch (localOrderErr) {
      developer.log("Local order merge note: $localOrderErr");
    }

    // Sort orders descending (most recent first)
    existingOrders.sort((a, b) {
      final aDate = _parseDate(a);
      final bDate = _parseDate(b);
      return bDate.compareTo(aDate);
    });

    profile['orders'] = existingOrders;

    // 4. Local Measurements Retrieval fallback if empty
    if (profile['measurements'] == null ||
        ((profile['measurements']['shirt'] == null || (profile['measurements']['shirt'] as Map).isEmpty) &&
         (profile['measurements']['pant'] == null || (profile['measurements']['pant'] as Map).isEmpty))) {
      try {
        final localMeasures = await _localDb.getMeasurementsByCustomer(
          (profile['_id'] ?? profile['id'] ?? customerId).toString(),
        );
        final Map<String, dynamic> shirtMap = {};
        final Map<String, dynamic> pantMap = {};

        for (final m in localMeasures) {
          final type = (m['item_type'] ?? '').toString().toLowerCase();
          final rawJson = m['measurements_json'] as String?;
          if (rawJson != null && rawJson.isNotEmpty) {
            try {
              final parsed = json.decode(rawJson) as Map<String, dynamic>;
              if (type.contains('pant') || type.contains('salwar')) {
                pantMap.addAll(parsed);
              } else {
                shirtMap.addAll(parsed);
              }
            } catch (_) {}
          }
        }

        profile['measurements'] = {
          'shirt': shirtMap,
          'pant': pantMap,
        };
      } catch (localMeasureErr) {
        developer.log("Local measurement note: $localMeasureErr");
      }
    }

    if (mounted) {
      setState(() {
        _customerData = profile;
        _isLoading = false;
      });
    }
  }

  DateTime _parseDate(dynamic order) {
    if (order is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    final raw = order['date'] ?? order['createdAt'] ?? order['order_date'];
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw != null) {
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title =
        _customerData != null ? _customerData!['name'] ?? 'Customer' : 'Loading...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading && _customerData == null
          ? const Center(child: CircularProgressIndicator())
          : _customerData == null
              ? Center(
                  child: Text(
                    'Failed to load customer profile',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )
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
                                    style: const TextStyle(
                                      color: AppTheme.brandPurple,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Phone: ${_customerData!['phone'] ?? 'N/A'}',
                                        style: const TextStyle(color: AppTheme.darkGrey),
                                      ),
                                      if (_customerData!['email'] != null &&
                                          _customerData!['email'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Email: ${_customerData!['email']}',
                                          style: const TextStyle(
                                            color: AppTheme.darkGrey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Unified Quick Action Buttons: Call, WhatsApp, and Primary New Order
                            Row(
                              children: [
                                if (_customerData!['phone'] != null &&
                                    _customerData!['phone'].toString().isNotEmpty) ...[
                                  Expanded(
                                    child: _actionButton(
                                      context: context,
                                      icon: Icons.phone,
                                      label: 'Call',
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest ??
                                          const Color(0xFF1F2937),
                                      foregroundColor: theme.colorScheme.onSurface,
                                      iconColor: AppTheme.brandPurple,
                                      onTap: () async {
                                        final uri = Uri.parse('tel:${_customerData!['phone']}');
                                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _actionButton(
                                      context: context,
                                      icon: Icons.chat,
                                      label: 'WhatsApp',
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      iconColor: Colors.white,
                                      onTap: () async {
                                        final clean = _customerData!['phone']
                                            .toString()
                                            .replaceAll(RegExp(r'\D'), '');
                                        final target = clean.startsWith('91') || clean.length != 10
                                            ? clean
                                            : '91$clean';
                                        final uri = Uri.parse('https://wa.me/$target');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            PrimaryNextAction(
                              label: 'New order with ${name.split(' ').first}',
                              icon: Icons.add_shopping_cart,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/create_order_step1',
                                  arguments: {
                                    'customer': _customerData,
                                    'measurements': _customerData?['measurements'],
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Measurements tab block
                      Text(
                        'Stored Fitting Measurements',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorColor: AppTheme.brandPurple,
                              labelColor: theme.colorScheme.primary,
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
                                  _buildShirtTab(
                                    _customerData!['measurements']?['shirt'] ?? {},
                                  ),
                                  _buildPantTab(
                                    _customerData!['measurements']?['pant'] ?? {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Order history list
                      Text(
                        'Order History',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_customerData!['orders'] == null ||
                          (_customerData!['orders'] as List).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No orders placed by this customer.',
                              style: TextStyle(color: AppTheme.darkGrey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_customerData!['orders'] as List).length,
                          itemBuilder: (context, index) {
                            final order = _customerData!['orders'][index];
                            final double amount = (order['price'] as num?)?.toDouble() ??
                                (order['total_amount'] as num?)?.toDouble() ??
                                0.0;
                            final String status = order['status'] ?? 'Incoming';
                            final String orderId =
                                (order['_id'] ?? order['id'] ?? '').toString();

                            final orderDate = _parseDate(order);
                            final String dateStr = orderDate.millisecondsSinceEpoch > 0
                                ? DateFormat('dd MMM yyyy').format(orderDate)
                                : 'Recent';

                            final String garment = (order['garmentType'] ??
                                    order['apparelType'] ??
                                    order['item_types'] ??
                                    order['description'] ??
                                    'Custom Order')
                                .toString();

                            return NeoCard(
                              onTap: () {
                                if (orderId.isNotEmpty) {
                                  Navigator.pushNamed(
                                    context,
                                    '/order_details',
                                    arguments: orderId,
                                  );
                                }
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.content_cut,
                                    color: AppTheme.brandPurple,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  garment,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  '₹${amount.toStringAsFixed(0)} • Date: $dateStr',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
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

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShirtTab(Map<String, dynamic> shirt) {
    if (shirt.isEmpty) {
      return const Center(
        child: Text(
          'No shirt measurements saved',
          style: TextStyle(color: AppTheme.darkGrey),
        ),
      );
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
          Text(
            'Notes: ${shirt['notes']}',
            style: const TextStyle(
              color: AppTheme.darkGrey,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPantTab(Map<String, dynamic> pant) {
    if (pant.isEmpty) {
      return const Center(
        child: Text(
          'No pant measurements saved',
          style: TextStyle(color: AppTheme.darkGrey),
        ),
      );
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
          Text(
            'Notes: ${pant['notes']}',
            style: const TextStyle(
              color: AppTheme.darkGrey,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
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
    } else if (s.contains('progress') ||
        s.contains('stitching') ||
        s.contains('cutting') ||
        s.contains('measuring')) {
      return AppTheme.brandPurple;
    } else if (s.contains('ready') ||
        s.contains('completed') ||
        s.contains('checking')) {
      return AppTheme.trustGreen;
    }
    return AppTheme.darkGrey;
  }
}
