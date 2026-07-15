import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

import 'package:stitchcraft/features/dashboard/widgets/line_chart_painter.dart';
import 'package:stitchcraft/features/dashboard/widgets/metric_card.dart';
import 'package:stitchcraft/features/dashboard/widgets/action_card.dart';

class DashboardScreen extends StatefulWidget {
  final bool isTab;
  const DashboardScreen({super.key, this.isTab = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _localDb = LocalDatabaseService();
  
  String _timeFilter = 'Weekly';
  
  double _cashReserve = 0.0;
  int _pendingOrdersCount = 0;
  List<double> _weeklyGraphPoints = [0, 0, 0, 0, 0, 0, 0];
  List<String> _graphLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];


  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Fetch SQLite Metrics
    final expenses = await _localDb.getAllExpenses();
    final orders = await _localDb.getAllOrders();

    final now = DateTime.now();
    List<dynamic> filteredOrders = [];
    List<dynamic> filteredExpenses = [];
    List<double> graphPoints = [];
    List<String> labels = [];

    if (_timeFilter == 'Today') {
      filteredOrders = orders.where((o) {
        final orderDateMs = o['order_date'] as int?;
        if (orderDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(orderDateMs);
        return date.isAfter(now.subtract(const Duration(hours: 24)));
      }).toList();

      filteredExpenses = expenses.where((e) {
        final expDateMs = e['expense_date'] as int?;
        if (expDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(expDateMs);
        return date.isAfter(now.subtract(const Duration(hours: 24)));
      }).toList();

      graphPoints = List.filled(6, 0.0);
      for (final o in filteredOrders) {
        final dateMs = o['order_date'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final hourDiff = now.difference(date).inHours;
        if (hourDiff >= 0 && hourDiff < 24) {
          final slotIndex = 5 - (hourDiff ~/ 4);
          if (slotIndex >= 0 && slotIndex < 6) {
            graphPoints[slotIndex] += 1.0;
          }
        }
      }
      labels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];

    } else if (_timeFilter == 'Weekly') {
      filteredOrders = orders.where((o) {
        final orderDateMs = o['order_date'] as int?;
        if (orderDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(orderDateMs);
        return date.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();

      filteredExpenses = expenses.where((e) {
        final expDateMs = e['expense_date'] as int?;
        if (expDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(expDateMs);
        return date.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();

      graphPoints = List.filled(7, 0.0);
      for (final o in filteredOrders) {
        final dateMs = o['order_date'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final dayDiff = now.difference(date).inDays;
        if (dayDiff >= 0 && dayDiff < 7) {
          final slotIndex = 6 - dayDiff;
          if (slotIndex >= 0 && slotIndex < 7) {
            graphPoints[slotIndex] += 1.0;
          }
        }
      }
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    } else { // Monthly
      filteredOrders = orders.where((o) {
        final orderDateMs = o['order_date'] as int?;
        if (orderDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(orderDateMs);
        return date.isAfter(now.subtract(const Duration(days: 30)));
      }).toList();

      filteredExpenses = expenses.where((e) {
        final expDateMs = e['expense_date'] as int?;
        if (expDateMs == null) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(expDateMs);
        return date.isAfter(now.subtract(const Duration(days: 30)));
      }).toList();

      graphPoints = List.filled(4, 0.0);
      for (final o in filteredOrders) {
        final dateMs = o['order_date'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final dayDiff = now.difference(date).inDays;
        if (dayDiff >= 0 && dayDiff < 28) {
          final slotIndex = 3 - (dayDiff ~/ 7);
          if (slotIndex >= 0 && slotIndex < 4) {
            graphPoints[slotIndex] += 1.0;
          }
        }
      }
      labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
    }

    double totalRevenue = 0.0;
    for (final o in filteredOrders) {
      totalRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    double totalExpense = 0.0;
    for (final e in filteredExpenses) {
      totalExpense += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final pending = filteredOrders.where((o) {
      final s = o['status']?.toString().toLowerCase() ?? '';
      return s != 'completed' && s != 'delivered';
    }).length;

    if (mounted) {
      setState(() {
        _cashReserve = totalRevenue - totalExpense;
        _pendingOrdersCount = pending;
        _weeklyGraphPoints = graphPoints;
        _graphLabels = labels;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? const Color(0xFF1A2231);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'StitchCraft Dashboard'),
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
                        _fetchDashboardData();
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
                        title: context.loc.cash_reserve,
                        value: '₹${_cashReserve.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppTheme.trustGreen,
                        onTap: () => Navigator.pushNamed(context, '/khata'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: context.loc.pending_orders,
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
                        '${context.loc.weekly_output} ($_timeFilter)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.loc.performance_summary,
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
                        children: _graphLabels
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
                      title: context.loc.new_order,
                      subtitle: 'ગ્રાહકનો નવો ઓર્ડર',
                      icon: Icons.content_cut,
                      color: AppTheme.brandPurple,
                      onTap: () => Navigator.pushNamed(context, '/create_order_step1'),
                    ),
                    ActionCard(
                      title: context.loc.khata_ledger,
                      subtitle: 'ખાતાવહી હિસાબ',
                      icon: Icons.menu_book,
                      color: AppTheme.trustGreen,
                      onTap: () => Navigator.pushNamed(context, '/khata'),
                    ),
                    ActionCard(
                      title: context.loc.inventory_stock,
                      subtitle: 'કાપડ અને મટીરીયલ',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.safetyOrange,
                      onTap: () => Navigator.pushNamed(context, '/inventory'),
                    ),
                    ActionCard(
                      title: context.loc.tailoring_staff,
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
