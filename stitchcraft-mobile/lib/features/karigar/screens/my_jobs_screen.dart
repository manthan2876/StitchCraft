import 'package:flutter/material.dart';
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

class _MyJobsScreenState extends State<MyJobsScreen> {
  final _localDb = LocalDatabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  String _filter = 'today'; // 'today' or 'all'
  List<Map<String, dynamic>> _jobs = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      _userId = user?.id;

      final allOrders = await _localDb.getAllOrders();
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      // Active workshop orders assigned to this karigar or general workshop tasks
      final workshopOrders = allOrders.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        final isClosed = status == 'delivered' || status == 'cancelled';
        if (isClosed) return false;

        // If explicitly assigned to this user or if unassigned workshop stage
        final assignedTo = o['assigned_to'] ?? o['karigar_id'] ?? o['karigarId'];
        if (_userId != null && assignedTo != null && assignedTo.toString().isNotEmpty) {
          if (assignedTo.toString() != _userId) return false;
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
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _advanceJobStage(Map<String, dynamic> order) async {
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final currentStatus = (order['status'] ?? 'Cutting').toString();

    String nextStatus;
    if (currentStatus.toLowerCase() == 'cutting') {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId moved to $nextStatus!'),
            backgroundColor: AppTheme.trustGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadJobs();
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.my_jobs,
        showDrawerButton: widget.isTab,
      ),
      body: Column(
        children: [
          // Filter Chips: Today vs All
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(context.loc.today),
                  selected: _filter == 'today',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _filter = 'today');
                      _loadJobs();
                    }
                  },
                  selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _filter == 'today' ? AppTheme.brandPurple : null,
                    fontWeight: _filter == 'today' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.loc.all),
                  selected: _filter == 'all',
                  onSelected: (val) {
                    if (val) {
                      setState(() => _filter = 'all');
                      _loadJobs();
                    }
                  },
                  selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _filter == 'all' ? AppTheme.brandPurple : null,
                    fontWeight: _filter == 'all' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _jobs.isEmpty
                    ? EmptyStateView(
                        icon: Icons.assignment_turned_in_outlined,
                        title: context.loc.no_assigned_jobs,
                        subtitle: 'All assigned garments for this period are complete.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        color: AppTheme.brandPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
                            final id = (job['id'] ?? job['_id'] ?? '').toString();
                            final customer = (job['customer_name'] ?? 'Customer').toString();
                            final garment = (job['garment_type'] ?? 'Garment').toString();
                            final status = (job['status'] ?? 'Stitching').toString();
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
                                        Text(
                                          'Order #$id',
                                          style: const TextStyle(
                                            color: AppTheme.darkGrey,
                                            fontSize: 13,
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
                                                arguments: {'order': job, 'orderId': id},
                                              ).then((_) => _loadJobs());
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
      ),
    );
  }
}

