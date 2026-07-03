import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/sync_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/localization_service.dart';
import 'package:stitchcraft/core/services/profile_service.dart';
import 'package:stitchcraft/features/dashboard/widgets/drawer_menu.dart';
import 'package:stitchcraft/features/dashboard/widgets/line_chart_painter.dart';
import 'package:stitchcraft/features/dashboard/widgets/metric_card.dart';
import 'package:stitchcraft/features/dashboard/widgets/action_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _syncService = SyncService();
  final _localDb = LocalDatabaseService();
  final _loc = LocalizationService();
  final _profileService = ProfileService();
  
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  String _timeFilter = 'Weekly';
  
  double _cashReserve = 0.0;
  int _pendingOrdersCount = 0;
  List<double> _weeklyGraphPoints = [0, 0, 0, 0, 0, 0, 0];

  String? _avatarUrl;
  String? _initials;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // 1. Fetch Profile Photo details
    final profile = await _profileService.fetchProfile();
    if (profile != null && mounted) {
      setState(() {
        _avatarUrl = profile['avatar'] as String?;
        final name = profile['name'] as String? ?? 'Masterji Ramesh';
        _initials = name
            .split(' ')
            .map((n) => n.isNotEmpty ? n[0] : '')
            .join('')
            .toUpperCase();
        if (_initials!.length > 2) {
          _initials = _initials!.substring(0, 2);
        }
      });
    }

    // 2. Fetch Sync Status
    final status = await _syncService.getSyncStatus();
    if (!mounted) return;
    setState(() {
      _pendingSyncCount = status['pendingCount'] ?? 0;
    });

    // 3. Fetch SQLite Metrics
    final expenses = await _localDb.getAllExpenses();
    final orders = await _localDb.getAllOrders();

    double totalRevenue = 0.0;
    for (final o in orders) {
      totalRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    double totalExpense = 0.0;
    for (final e in expenses) {
      totalExpense += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final pending = orders.where((o) {
      final s = o['status']?.toString().toLowerCase() ?? '';
      return s != 'completed' && s != 'delivered';
    }).length;

    // 4. Compile Graph Points (Last 7 Days)
    final List<double> graphPoints = [0, 0, 0, 0, 0, 0, 0];
    final now = DateTime.now();
    for (final o in orders) {
      final orderDateMs = o['order_date'] as int?;
      if (orderDateMs != null) {
        final orderDate = DateTime.fromMillisecondsSinceEpoch(orderDateMs);
        final difference = now.difference(orderDate).inDays;
        if (difference >= 0 && difference < 7) {
          final dayIndex = 6 - difference;
          graphPoints[dayIndex] += 1.0;
        }
      }
    }

    if (mounted) {
      setState(() {
        _cashReserve = totalRevenue - totalExpense;
        _pendingOrdersCount = pending;
        _weeklyGraphPoints = graphPoints;
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncAll();
      await _fetchDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync Complete! All local records synchronized.'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Failed: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? const Color(0xFF1A2231);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_loc.t(context, 'dashboard_title')),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Badge(
                    label: Text('$_pendingSyncCount'),
                    isLabelVisible: _pendingSyncCount > 0,
                    child: const Icon(Icons.sync),
                  ),
            onPressed: _isSyncing ? null : _triggerSync,
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/profile');
              _fetchDashboardData();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.brandPurple,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Text(
                          _initials ?? 'MR',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: cardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Today', 'Weekly', 'Monthly'].map((filter) {
                    final isSelected = _timeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _timeFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.brandPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.darkGrey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Top Metrics Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: _loc.t(context, 'cash_reserve'),
                        value: '₹${_cashReserve.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppTheme.trustGreen,
                        onTap: () => Navigator.pushNamed(context, '/khata'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: _loc.t(context, 'pending_orders'),
                        value: '$_pendingOrdersCount Active',
                        icon: Icons.pending_actions,
                        color: AppTheme.safetyOrange,
                        onTap: () => Navigator.pushNamed(context, '/orders_pending'),
                      ),
                    ),
                  ],
                ),
              ),

              // Performance Graph Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_loc.t(context, 'weekly_output')} ($_timeFilter)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _loc.t(context, 'performance_summary'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: LineChartPainter(_weeklyGraphPoints),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            .map((label) => Text(
                                  label,
                                  style: theme.textTheme.labelSmall,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Operations Grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    ActionCard(
                      title: _loc.t(context, 'new_order'),
                      subtitle: 'ગ્રાહકનો નવો ઓર્ડર',
                      icon: Icons.content_cut,
                      color: AppTheme.brandPurple,
                      onTap: () => Navigator.pushNamed(context, '/create_order_step1'),
                    ),
                    ActionCard(
                      title: _loc.t(context, 'khata_ledger'),
                      subtitle: 'ખાતાવહી હિસાબ',
                      icon: Icons.menu_book,
                      color: AppTheme.trustGreen,
                      onTap: () => Navigator.pushNamed(context, '/khata'),
                    ),
                    ActionCard(
                      title: _loc.t(context, 'inventory_stock'),
                      subtitle: 'કાપડ અને મટીરીયલ',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.safetyOrange,
                      onTap: () => Navigator.pushNamed(context, '/inventory'),
                    ),
                    ActionCard(
                      title: _loc.t(context, 'tailoring_staff'),
                      subtitle: 'કારીગરો અને મશીન',
                      icon: Icons.engineering_outlined,
                      color: AppTheme.brandPurple,
                      onTap: () => Navigator.pushNamed(context, '/karigars'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
