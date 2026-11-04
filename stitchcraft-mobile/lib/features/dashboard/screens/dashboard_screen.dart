import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/widgets/state_views.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';

import 'package:stitchcraft/features/dashboard/widgets/line_chart_painter.dart';

class _CashFlowItem {
  final double amount;
  final DateTime date;
  const _CashFlowItem({required this.amount, required this.date});
}

class DashboardScreen extends StatefulWidget {
  final bool isTab;
  const DashboardScreen({super.key, this.isTab = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  String _timeFilter = 'Weekly';

  int _dueTodayCount = 0;
  int _lateCount = 0;
  double _moneyToCollect = 0.0;
  Map<String, dynamic>? _nextUpOrder;
  int _periodOrderCount = 0;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _loadError;

  List<double> _incomePoints = [0, 0, 0, 0, 0, 0, 0];
  List<double> _expensePoints = [0, 0, 0, 0, 0, 0, 0];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _netProfit = 0.0;
  List<String> _graphLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    // Check internet connectivity to dynamically determine offline state
    bool offline = false;
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (lookup.isEmpty || lookup[0].rawAddress.isEmpty) {
        offline = true;
      }
    } catch (_) {
      offline = true;
    }

    try {
      // Fetch SQLite metrics for orders and expenses
      final orders = await _localDb.getAllOrders();
      final expenses = await _localDb.getAllExpenses();

      final now = DateTime.now();

      // 1. Extract income entries: ONLY when payment was collected (cash/online advance or full payment)
      final List<_CashFlowItem> incomeItems = [];
      for (final o in orders) {
        final orderDate = _extractDate(
          o['order_date'] ?? o['createdAt'] ?? o['date'],
        );
        if (orderDate == null) continue;

        final total = (o['total_amount'] as num?)?.toDouble() ??
            (o['price'] as num?)?.toDouble() ??
            0.0;
        final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
        final status = (o['status']?.toString() ?? '').toLowerCase();

        final double collectedAmount = advance;

        if (collectedAmount > 0) {
          // Attributed to the payment collection billing date
          incomeItems.add(_CashFlowItem(
            amount: collectedAmount,
            date: orderDate,
          ));
        }
      }

      // 2. Extract expense entries
      final List<_CashFlowItem> expenseItems = [];
      for (final e in expenses) {
        final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
        final expDate = _extractDate(e['date'] ?? e['createdAt']);
        if (amt > 0 && expDate != null) {
          expenseItems.add(_CashFlowItem(amount: amt, date: expDate));
        }
      }

      // 3. Bucket both income and expenses based on _timeFilter
      List<double> incomeGraph = [];
      List<double> expenseGraph = [];
      List<String> labels = [];
      int periodOrders = 0;

      final todayMidnight = DateTime(now.year, now.month, now.day);

      if (_timeFilter == 'Today') {
        final cutoff = now.subtract(const Duration(hours: 24));
        periodOrders = orders.where((o) {
          final d = _extractDate(o['order_date'] ?? o['createdAt'] ?? o['date']);
          if (d == null) return false;
          return d.isAfter(cutoff);
        }).length;

        incomeGraph = List.filled(6, 0.0);
        expenseGraph = List.filled(6, 0.0);

        for (final item in incomeItems) {
          if (item.date.isAfter(cutoff)) {
            final hourDiff = now.difference(item.date).inHours;
            if (hourDiff >= 0 && hourDiff < 24) {
              final slotIndex = 5 - (hourDiff ~/ 4);
              if (slotIndex >= 0 && slotIndex < 6) {
                incomeGraph[slotIndex] += item.amount;
              }
            }
          }
        }

        for (final item in expenseItems) {
          if (item.date.isAfter(cutoff)) {
            final hourDiff = now.difference(item.date).inHours;
            if (hourDiff >= 0 && hourDiff < 24) {
              final slotIndex = 5 - (hourDiff ~/ 4);
              if (slotIndex >= 0 && slotIndex < 6) {
                expenseGraph[slotIndex] += item.amount;
              }
            }
          }
        }

        labels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];
      } else if (_timeFilter == 'Weekly') {
        // Last 7 calendar days ending today
        final startOfPeriod = todayMidnight.subtract(const Duration(days: 6));
        final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

        periodOrders = orders.where((o) {
          final d = _extractDate(o['order_date'] ?? o['createdAt'] ?? o['date']);
          if (d == null) return false;
          return d.isAfter(startOfPeriod.subtract(const Duration(milliseconds: 1))) &&
              d.isBefore(endOfPeriod);
        }).length;

        incomeGraph = List.filled(7, 0.0);
        expenseGraph = List.filled(7, 0.0);

        for (final item in incomeItems) {
          final itemMidnight = DateTime(item.date.year, item.date.month, item.date.day);
          final dayDiff = todayMidnight.difference(itemMidnight).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            final slotIndex = 6 - dayDiff;
            if (slotIndex >= 0 && slotIndex < 7) {
              incomeGraph[slotIndex] += item.amount;
            }
          }
        }

        for (final item in expenseItems) {
          final itemMidnight = DateTime(item.date.year, item.date.month, item.date.day);
          final dayDiff = todayMidnight.difference(itemMidnight).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            final slotIndex = 6 - dayDiff;
            if (slotIndex >= 0 && slotIndex < 7) {
              expenseGraph[slotIndex] += item.amount;
            }
          }
        }

        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        labels = List<String>.generate(7, (i) {
          final d = todayMidnight.subtract(Duration(days: 6 - i));
          return weekdayNames[d.weekday - 1];
        });
      } else {
        // Monthly (last 28 calendar days in 4 weekly slots)
        final startOfPeriod = todayMidnight.subtract(const Duration(days: 27));
        final endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

        periodOrders = orders.where((o) {
          final d = _extractDate(o['order_date'] ?? o['createdAt'] ?? o['date']);
          if (d == null) return false;
          return d.isAfter(startOfPeriod.subtract(const Duration(milliseconds: 1))) &&
              d.isBefore(endOfPeriod);
        }).length;

        incomeGraph = List.filled(4, 0.0);
        expenseGraph = List.filled(4, 0.0);

        for (final item in incomeItems) {
          final itemMidnight = DateTime(item.date.year, item.date.month, item.date.day);
          final dayDiff = todayMidnight.difference(itemMidnight).inDays;
          if (dayDiff >= 0 && dayDiff < 28) {
            final slotIndex = 3 - (dayDiff ~/ 7);
            if (slotIndex >= 0 && slotIndex < 4) {
              incomeGraph[slotIndex] += item.amount;
            }
          }
        }

        for (final item in expenseItems) {
          final itemMidnight = DateTime(item.date.year, item.date.month, item.date.day);
          final dayDiff = todayMidnight.difference(itemMidnight).inDays;
          if (dayDiff >= 0 && dayDiff < 28) {
            final slotIndex = 3 - (dayDiff ~/ 7);
            if (slotIndex >= 0 && slotIndex < 4) {
              expenseGraph[slotIndex] += item.amount;
            }
          }
        }

        labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      }

      final double totalIncome = incomeGraph.fold(0.0, (sum, val) => sum + val);
      final double totalExpense = expenseGraph.fold(0.0, (sum, val) => sum + val);
      final double netProfit = totalIncome - totalExpense;

      // Priority Action counts
      final startOfToday = DateTime(now.year, now.month, now.day);
      final dueToday = orders.where((o) {
        final due = _orderDate(o['due_date']);
        return due != null &&
            due.year == startOfToday.year &&
            due.month == startOfToday.month &&
            due.day == startOfToday.day &&
            !_isClosedStatus(o['status']);
      }).toList();

      final late = orders.where((o) {
        final due = _orderDate(o['due_date']);
        return due != null &&
            due.isBefore(startOfToday) &&
            !_isClosedStatus(o['status']);
      }).toList();

      final moneyToCollect = orders.fold<double>(0, (sum, order) {
        final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
        final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0;
        return sum + (total - advance).clamp(0, double.infinity);
      });

      int effectiveDueToday = dueToday.length;
      int effectiveLate = late.length;
      double effectiveMoneyToCollect = moneyToCollect;

      if (!offline) {
        try {
          final token = await _authService.getToken();
          if (token != null) {
            final statsResp = await http.get(
              Uri.parse('${AuthService.baseUrl}/dashboard/stats'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ).timeout(const Duration(seconds: 4));

            if (statsResp.statusCode == 200) {
              final stats = json.decode(statsResp.body);
              if (stats is Map<String, dynamic>) {
                if (stats['todayDeliveryCount'] is num) {
                  effectiveDueToday = (stats['todayDeliveryCount'] as num).toInt();
                }
                if (stats['lateDeliveryCount'] is num) {
                  effectiveLate = (stats['lateDeliveryCount'] as num).toInt();
                }
                if (stats['totalUdharAmount'] is num) {
                  effectiveMoneyToCollect = (stats['totalUdharAmount'] as num).toDouble();
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Server dashboard stats fallback: $e");
        }
      }

      Map<String, dynamic>? nextUp;
      if (late.isNotEmpty) {
        nextUp = late.first;
      } else if (dueToday.isNotEmpty) {
        nextUp = dueToday.first;
      } else {
        nextUp = orders.where((o) => !_isClosedStatus(o['status'])).firstOrNull;
      }

      if (mounted) {
        setState(() {
          _isOffline = offline;
          _dueTodayCount = effectiveDueToday;
          _lateCount = effectiveLate;
          _moneyToCollect = effectiveMoneyToCollect;
          _nextUpOrder = nextUp;
          _periodOrderCount = periodOrders;
          _incomePoints = incomeGraph;
          _expensePoints = expenseGraph;
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _netProfit = netProfit;
          _graphLabels = labels;
        });
      }

      _checkNewNotifications();
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load dashboard data. Pull to retry.';
        });
      }
      debugPrint('Dashboard load failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _extractDate(dynamic val) {
    if (val == null) return null;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is DateTime) return val;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    final intVal = int.tryParse(str);
    if (intVal != null && str.length >= 10) {
      return DateTime.fromMillisecondsSinceEpoch(intVal);
    }
    return DateTime.tryParse(str);
  }

  DateTime? _orderDate(Object? value) => _extractDate(value);

  bool _isClosedStatus(Object? value) {
    final status = value?.toString().toLowerCase();
    return status == 'delivered' || status == 'cancelled';
  }

  Future<void> _checkNewNotifications() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        final prefs = await SharedPreferences.getInstance();
        final alertedIds =
            prefs.getStringList('alerted_notification_ids') ?? [];
        final List<String> newAlertedIds = List.from(alertedIds);
        bool updated = false;

        for (final n in list) {
          final String id = n['_id'] ?? '';
          final String message = n['message'] ?? '';
          final bool isRead = n['read'] ?? false;
          if (!isRead && !alertedIds.contains(id)) {
            await NotificationService().showInstantNotification(
              "StitchCraft Alert",
              message,
              id: id.hashCode,
            );
            newAlertedIds.add(id);
            updated = true;
          }
        }
        if (updated) {
          await prefs.setStringList('alerted_notification_ids', newAlertedIds);
        }
      }
    } catch (e) {
      debugPrint("Error checking new notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? const Color(0xFF1A2231);

    final bool isGraphEmpty =
        _incomePoints.every((p) => p == 0) && _expensePoints.every((p) => p == 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'StitchCraft Dashboard'),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: _isLoading && isGraphEmpty
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: AppTheme.alertRed.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _fetchDashboardData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Filter Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.brandPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                filter,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.darkGrey,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Showing offline banner ONLY when actually offline
                    if (_isOffline)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.safetyOrange.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.safetyOrange.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_done_outlined,
                                size: 18,
                                color: AppTheme.safetyOrange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.loc.dashboard_data_local,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // TODAY QUEUE (UX-03: Action over analytics)
                    SectionHeader(
                      title: context.loc.today.toUpperCase(),
                      subtitle: 'Urgent counter actions and collections',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _priorityCard(
                            context,
                            context.loc.due_today,
                            '$_dueTodayCount orders',
                            Icons.today,
                            AppTheme.brandPurple,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderListScreen(
                                  title: context.loc.due_today,
                                  statusFilter: 'due_today',
                                ),
                              ),
                            ),
                          ),
                          _priorityCard(
                            context,
                            context.loc.late_orders,
                            '$_lateCount orders',
                            Icons.warning_amber_rounded,
                            AppTheme.alertRed,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderListScreen(
                                  title: context.loc.late_orders,
                                  statusFilter: 'late',
                                ),
                              ),
                            ),
                          ),
                          _priorityCard(
                            context,
                            context.loc.collect_money,
                            _formatIndianCurrency(_moneyToCollect),
                            Icons.account_balance_wallet_outlined,
                            AppTheme.trustGreen,
                            () => Navigator.pushNamed(context, '/khata'),
                          ),
                          const SizedBox(height: 12),
                          PrimaryNextAction(
                            label: context.loc.start_new_order,
                            icon: Icons.add,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/create_order_customer',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // NEXT UP: Urgent Order Preview
                    if (_nextUpOrder != null) ...[
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: context.loc.next_up.toUpperCase(),
                        subtitle: 'Most urgent garment in production',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: NeoCard(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/order_details',
                              arguments: _nextUpOrder!['id'] ?? _nextUpOrder!['_id'] ?? '',
                            ).then((_) => _fetchDashboardData());
                          },
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_nextUpOrder!['customer_name'] ?? 'Customer'} • ${_nextUpOrder!['garment_type'] ?? 'Garment'}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  StatusBadge(
                                    status: (_nextUpOrder!['status'] ?? 'Incoming').toString(),
                                    compact: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order #${_nextUpOrder!['id'] ?? ''} • Due: ${_nextUpOrder!['due_date'] != null ? _nextUpOrder!['due_date'].toString().split('T').first : 'Today'}',
                                style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Open Order',
                                    style: TextStyle(
                                      color: AppTheme.brandPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 16, color: AppTheme.brandPurple),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Performance Graph Section (Dual Area Chart: Income vs Expense)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: NeoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash Flow ($_timeFilter)',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Collected Payments vs Expenses',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _netProfit >= 0
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Net: ${_formatIndianCurrency(_netProfit)}',
                                    style: TextStyle(
                                      color: _netProfit >= 0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF43F5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Legend Indicators for Income and Expenses
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _legendBadge(
                                  color: const Color(0xFF10B981),
                                  label: 'Income: ${_formatIndianCurrency(_totalIncome)}',
                                ),
                                _legendBadge(
                                  color: const Color(0xFFF43F5E),
                                  label: 'Expense: ${_formatIndianCurrency(_totalExpense)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Area Chart Canvas
                            SizedBox(
                              height: 130,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: LineChartPainter(
                                  incomePoints: _incomePoints,
                                  expensePoints: _expensePoints,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dynamic Timeline Labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _graphLabels
                                  .map(
                                    (label) => Text(
                                      label,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.darkGrey,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _legendBadge({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _priorityCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: NeoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatIndianCurrency(double amount) {
    return CurrencyUtils.formatINR(amount, showDecimals: false);
  }
}
