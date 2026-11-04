import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class MyJobsScreen extends StatefulWidget {
  final bool isTab;
  const MyJobsScreen({super.key, this.isTab = false});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  final _localDb = LocalDatabaseService();
  final _authService = AuthService();

  late TabController _tabController;
  bool _isLoading = true;
  String _filter = 'all'; // 'today' or 'all'
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _partnerJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllJobs() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadWorkshopJobs(),
      _loadPartnerJobs(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWorkshopJobs() async {
    try {
      final allOrders = await _localDb.getAllOrders();
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final workshopOrders = allOrders.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        final isClosed = status == 'delivered' || status == 'cancelled';
        if (isClosed) return false;

        // Skip orders that are outsourced to someone else
        final delegatedTo = o['delegated_to_shop_name'] ?? o['delegatedToShopName'];
        final delegationStatus = o['delegation_status'] ?? o['delegationStatus'];
        if (delegatedTo != null && delegatedTo.toString().isNotEmpty && delegationStatus != 'revoked') {
          return false;
        }

        if (_filter == 'today') {
          final dueStr = o['due_date']?.toString();
          if (dueStr != null) {
            final due = DateTime.tryParse(dueStr);
            if (due != null) {
              final dueMidnight = DateTime(due.year, due.month, due.day);
              return dueMidnight.isAtSameMomentAs(todayDate) || dueMidnight.isBefore(todayDate);
            }
          }
        }
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _jobs = workshopOrders;
        });
      }
    } catch (e) {
      developer.log('Error loading workshop jobs: $e');
    }
  }

  Future<void> _loadPartnerJobs() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final res = await http.get(
          Uri.parse('${AuthService.baseUrl}/orders?type=partner_jobs'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 200) {
          final List list = json.decode(res.body);
          if (mounted) {
            setState(() {
              _partnerJobs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            });
            return;
          }
        }
      }
    } catch (e) {
      developer.log('Error fetching partner jobs from server: $e');
    }

    // Fallback to local DB records where origin_shop_name is set
    try {
      final localOrders = await _localDb.getAllOrders();
      final pJobs = localOrders.where((o) {
        final origin = o['origin_shop_name'] ?? o['originShopName'];
        return origin != null && origin.toString().isNotEmpty;
      }).toList();
      if (mounted) {
        setState(() {
          _partnerJobs = pJobs;
        });
      }
    } catch (_) {}
  }

  Future<void> _advanceJobStage(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final currentStatus = (order['status'] ?? 'Cutting').toString();

    String nextStatus;
    if (currentStatus.toLowerCase() == 'incoming') {
      nextStatus = 'Cutting';
    } else if (currentStatus.toLowerCase() == 'cutting') {
      nextStatus = 'Stitching';
    } else if (currentStatus.toLowerCase() == 'stitching') {
      nextStatus = 'Checking';
    } else {
      nextStatus = 'Ready';
    }

    try {
      await _localDb.updateRecord('orders', orderId, {
        'status': nextStatus,
        'sync_status': 3, // pending PUT update
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Best effort PUT to server
      try {
        final token = await _authService.getToken();
        if (token != null) {
          await http.put(
            Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'status': nextStatus}),
          );
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order moved to $nextStatus!'),
            backgroundColor: AppTheme.trustGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadWorkshopJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stage: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  Future<void> _advancePartnerJobStage(Map<String, dynamic> job) async {
    final orderId = (job['id'] ?? job['_id'] ?? '').toString();
    final currentStatus = (job['status'] ?? 'Cutting').toString();

    String nextStatus;
    if (currentStatus.toLowerCase() == 'incoming') {
      nextStatus = 'Cutting';
    } else if (currentStatus.toLowerCase() == 'cutting') {
      nextStatus = 'Stitching';
    } else if (currentStatus.toLowerCase() == 'stitching') {
      nextStatus = 'Checking';
    } else {
      nextStatus = 'Ready';
    }

    try {
      final token = await _authService.getToken();
      if (token != null) {
        final response = await http.put(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'status': nextStatus}),
        );
        if (response.statusCode != 200) {
          throw Exception(json.decode(response.body)['message'] ?? 'Failed to update order');
        }
      }

      // Also update local record
      try {
        await _localDb.updateRecord('orders', orderId, {
          'status': nextStatus,
          'delegation_status': (nextStatus == 'Ready' || nextStatus == 'Delivered') ? 'completed' : 'in_progress',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {}

      if (mounted) {
        final isReady = nextStatus == 'Ready';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isReady
                  ? 'Order marked Ready! Push notification sent to original tailor.'
                  : 'Partner job moved to $nextStatus!',
            ),
            backgroundColor: AppTheme.trustGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadPartnerJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stage: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Workshop & Partner Jobs',
        showDrawerButton: widget.isTab,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandPurple,
          unselectedLabelColor: AppTheme.darkGrey,
          indicatorColor: AppTheme.brandPurple,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build_circle_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Workshop (${_jobs.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.handshake_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Partner Jobs (${_partnerJobs.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkshopTab(theme),
          _buildPartnerJobsTab(theme),
        ],
      ),
    );
  }

  Widget _buildWorkshopTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Filter Chips: All vs Today
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Jobs'),
                selected: _filter == 'all',
                onSelected: (val) {
                  if (val) {
                    setState(() => _filter = 'all');
                    _loadWorkshopJobs();
                  }
                },
                selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _filter == 'all' ? AppTheme.brandPurple : null,
                  fontWeight: _filter == 'all' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.loc.today),
                selected: _filter == 'today',
                onSelected: (val) {
                  if (val) {
                    setState(() => _filter = 'today');
                    _loadWorkshopJobs();
                  }
                },
                selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _filter == 'today' ? AppTheme.brandPurple : null,
                  fontWeight: _filter == 'today' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingView()
              : _jobs.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'No Workshop Tasks',
                      subtitle: 'All in-house garments are currently up to date.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWorkshopJobs,
                      color: AppTheme.brandPurple,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final job = _jobs[index];
                          final id = (job['id'] ?? job['_id'] ?? '').toString();
                          final customer = (job['customer_name'] ?? job['customerName'] ?? 'Customer').toString();
                          final garment = (job['garment_type'] ?? job['garmentType'] ?? 'Garment').toString();
                          final status = (job['status'] ?? 'Cutting').toString();
                          final syncStatus = (job['sync_status'] as num?)?.toInt() ?? 0;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? AppTheme.lightGrey : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$garment • $customer',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      StatusBadge(status: status, compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Order #${id.length > 8 ? id.substring(0, 8) : id}',
                                          style: const TextStyle(
                                            color: AppTheme.darkGrey,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (syncStatus != 0) ...[
                                        const SizedBox(width: 8),
                                        const PendingChip(compact: true),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 46),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/order_details',
                                              arguments: id,
                                            ).then((_) => _loadWorkshopJobs());
                                          },
                                          child: const Text('Open Job'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.brandPurple,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 46),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _advanceJobStage(job),
                                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                          label: Text(
                                            status.toLowerCase() == 'checking'
                                                ? context.loc.mark_ready
                                                : 'Next Stage',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPartnerJobsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return _isLoading
        ? const LoadingView()
        : _partnerJobs.isEmpty
            ? const EmptyStateView(
                icon: Icons.handshake_outlined,
                title: 'No Partner Jobs',
                subtitle: 'No orders have been outsourced to your shop from other tailors yet.',
              )
            : RefreshIndicator(
                onRefresh: _loadPartnerJobs,
                color: AppTheme.brandPurple,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _partnerJobs.length,
                  itemBuilder: (context, index) {
                    final job = _partnerJobs[index];
                    final id = (job['_id'] ?? job['id'] ?? '').toString();
                    final customer = (job['customerName'] ?? job['customer_name'] ?? 'Customer').toString();
                    final garment = (job['garmentType'] ?? job['garment_type'] ?? 'Garment').toString();
                    final status = (job['status'] ?? 'Stitching').toString();
                    final originShop = (job['originShopName'] ?? job['origin_shop_name'] ?? 'Partner Tailor').toString();
                    final originPhone = (job['originPhone'] ?? job['origin_phone'] ?? '').toString();
                    final notes = (job['delegatedNotes'] ?? job['delegated_notes'] ?? '').toString();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppTheme.brandPurple,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Garment & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$garment • $customer',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(status: status, compact: true),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Origin Shop Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.brandPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.brandPurple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'From: $originShop',
                                      style: const TextStyle(
                                        color: AppTheme.brandPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (originPhone.isNotEmpty)
                                    InkWell(
                                      onTap: () async {
                                        final uri = Uri.parse('tel:$originPhone');
                                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.phone, size: 16, color: AppTheme.trustGreen),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Note: $notes',
                                style: TextStyle(
                                  color: isDark ? AppTheme.lightGrey : AppTheme.darkGrey,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 46),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/order_details',
                                        arguments: id,
                                      ).then((_) => _loadPartnerJobs());
                                    },
                                    child: const Text('Open Job'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brandPurple,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 46),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _advancePartnerJobStage(job),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                    label: Text(
                                      status.toLowerCase() == 'checking'
                                          ? 'Mark Ready'
                                          : 'Next Stage',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}
