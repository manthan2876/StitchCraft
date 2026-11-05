import 'dart:async';
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
import 'package:stitchcraft/core/services/database_service.dart';
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
  bool _isLoading = true;
  bool _isOffline = false;
  String? _loadError;

  List<double> _incomePoints = [0, 0, 0, 0, 0, 0, 0];
  List<double> _expensePoints = [0, 0, 0, 0, 0, 0, 0];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _netProfit = 0.0;
  List<String> _graphLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  StreamSubscription<void>? _orderSub;
  StreamSubscription<void>? _expenseSub;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _orderSub = DatabaseService.orderSignal.stream.listen((_) {
      if (mounted) _fetchDashboardData();
    });
    _expenseSub = DatabaseService.expenseSignal.stream.listen((_) {
      if (mounted) _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _expenseSub?.cancel();
    super.dispose();
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

    // 0. If online, sync discrete payment transactions from server journal into order_payments
    final prefs = await SharedPreferences.getInstance();
    final currentShopId = prefs.getString('shopId');

    if (!offline) {
      try {
        final token = await _authService.getToken();
        if (token != null) {
          final txResp = await http.get(
            Uri.parse('${AuthService.baseUrl}/ledger/journal?category=Payments'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 4));

          if (txResp.statusCode == 200) {
            final txData = json.decode(txResp.body);
            if (txData is List) {
              for (final item in txData) {
                final refId = (item['referenceId'] ?? item['orderId'] ?? '').toString();
                final txId = (item['_id'] ?? item['id'] ?? '').toString();
                final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                final pDate = _extractDate(item['date']);
                if (amt > 0 && pDate != null && txId.isNotEmpty && refId.isNotEmpty) {
                  try {
                    await _localDb.insertPayment({
                      'id': txId,
                      'order_id': refId,
                      'amount': amt,
                      'payment_method': (item['paymentMethod'] ?? 'Cash').toString(),
                      'date': pDate.millisecondsSinceEpoch,
                      'shop_id': currentShopId,
                      'sync_status': 0,
                      'updated_at': pDate.millisecondsSinceEpoch,
                    });
                  } catch (_) {}
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Journal payments fetch note: $e');
      }
    }

    try {
      // Fetch SQLite metrics strictly scoped to this tailor's shop
      final orders = await _localDb.getAllOrders(shopId: currentShopId);
      final expenses = await _localDb.getAllExpenses(shopId: currentShopId);
      final localPayments = await _localDb.getAllPayments(shopId: currentShopId);

      final now = DateTime.now();

      // Identify any outsourced jobs coming from other tailors to ensure they never leak into this tailor's graph
      final Set<String> outsourcedOrderIds = {};
      for (final o in orders) {
        final orderId = (o['id'] ?? o['_id'] ?? '').toString();
        final bool isPartnerJob = o['isPartnerJob'] == true ||
            o['isOutsourcedToMe'] == true ||
            (o['origin_shop_name'] != null && o['origin_shop_name'].toString().isNotEmpty) ||
            (currentShopId != null &&
                o['delegated_to_shop_id'] != null &&
                o['delegated_to_shop_id'].toString() == currentShopId &&
                o['shop_id'] != null &&
                o['shop_id'].toString() != currentShopId);

        if (isPartnerJob && orderId.isNotEmpty) {
          outsourcedOrderIds.add(orderId);
        }
      }

      // 1. Separate expenses table into manual incomes and actual expenses
      final List<_CashFlowItem> incomeItems = [];
      final List<_CashFlowItem> expenseItems = [];

      for (final e in expenses) {
        final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
        final expDate = _extractDate(e['date'] ?? e['createdAt'] ?? e['updated_at']);
        if (amt <= 0 || expDate == null) continue;

        final type = (e['type'] ?? 'expense').toString().toLowerCase();
        final cat = (e['category'] ?? '').toString().toLowerCase();
        final isIncome = type == 'income' || cat.startsWith('income');

        if (isIncome) {
          incomeItems.add(_CashFlowItem(amount: amt, date: expDate));
        } else {
          expenseItems.add(_CashFlowItem(amount: amt, date: expDate));
        }
      }

      // 2. Add all discrete payments recorded for this tailor's own orders
      final Set<String> ordersWithDiscretePayments = {};
      for (final p in localPayments) {
        final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
        final pDate = _extractDate(p['date'] ?? p['updated_at']);
        final orderId = (p['order_id'] ?? '').toString();
        if (amt <= 0 || pDate == null) continue;

        // Disallow payments belonging to outsourced orders of another tailor
        if (orderId.isNotEmpty && outsourcedOrderIds.contains(orderId)) {
          continue;
        }

        if (orderId.isNotEmpty) {
          ordersWithDiscretePayments.add(orderId);
        }
        incomeItems.add(_CashFlowItem(amount: amt, date: pDate));
      }

      // 3. Extract income from orders that don't yet have discrete records in order_payments
      for (final o in orders) {
        final orderId = (o['id'] ?? o['_id'] ?? '').toString();
        if (orderId.isNotEmpty && ordersWithDiscretePayments.contains(orderId)) {
          // Already accounted for via discrete payments in order_payments
          continue;
        }

        // Never populate advance or income from another tailor's outsourced order into this tailor's graph
        if (orderId.isNotEmpty && outsourcedOrderIds.contains(orderId)) {
          continue;
        }

        final status = (o['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled') continue;

        final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
        final collectedAmount = advance;
        if (collectedAmount <= 0) continue;

        final orderDate = _extractDate(
          o['order_date'] ?? o['createdAt'] ?? o['date'],
        );
        final updateDate = _extractDate(o['updated_at']);

        // Check if an older order was updated today with a payment (offline/unmigrated fallback)
        if (orderDate != null && updateDate != null && !_isSameDay(orderDate, updateDate)) {
          if (_isSameDay(updateDate, now)) {
            // Keep booking advance on orderDate (so yesterday keeps its bump),
            // and attribute the recent payment bump to updateDate
            final half = collectedAmount / 2.0;
            incomeItems.add(_CashFlowItem(amount: half, date: orderDate));
            incomeItems.add(_CashFlowItem(amount: half, date: updateDate));
          } else {
            // If updated in the past without discrete payment rows, attribute to booking date
            incomeItems.add(_CashFlowItem(amount: collectedAmount, date: orderDate));
          }
        } else {
          final paymentDate = orderDate ?? updateDate ?? now;
          incomeItems.add(_CashFlowItem(
            amount: collectedAmount,
            date: paymentDate,
          ));
        }
      }

      // 3. Bucket both income and expenses based on _timeFilter
      List<double> incomeGraph = [];
      List<double> expenseGraph = [];
      List<String> labels = [];

      final todayMidnight = DateTime(now.year, now.month, now.day);

      if (_timeFilter == 'Today') {
        incomeGraph = List.filled(6, 0.0);
        expenseGraph = List.filled(6, 0.0);

        for (final item in incomeItems) {
          if (_isSameDay(item.date, now)) {
            final slotIndex = (item.date.hour ~/ 4).clamp(0, 5);
            incomeGraph[slotIndex] += item.amount;
          }
        }

        for (final item in expenseItems) {
          if (_isSameDay(item.date, now)) {
            final slotIndex = (item.date.hour ~/ 4).clamp(0, 5);
            expenseGraph[slotIndex] += item.amount;
          }
        }

        labels = ['12am', '4am', '8am', '12pm', '4pm', '8pm'];
      } else if (_timeFilter == 'Weekly') {
        // Last 7 calendar days ending today
        incomeGraph = List.filled(7, 0.0);
        expenseGraph = List.filled(7, 0.0);

        for (final item in incomeItems) {
          final dayDiff = _calendarDaysBetween(item.date, now);
          if (dayDiff >= 0 && dayDiff < 7) {
            final slotIndex = 6 - dayDiff;
            incomeGraph[slotIndex] += item.amount;
          }
        }

        for (final item in expenseItems) {
          final dayDiff = _calendarDaysBetween(item.date, now);
          if (dayDiff >= 0 && dayDiff < 7) {
            final slotIndex = 6 - dayDiff;
            expenseGraph[slotIndex] += item.amount;
          }
        }

        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        labels = List<String>.generate(7, (i) {
          final d = todayMidnight.subtract(Duration(days: 6 - i));
          return weekdayNames[d.weekday - 1];
        });
      } else {
        // Monthly (last 28 calendar days in 4 weekly slots)
        incomeGraph = List.filled(4, 0.0);
        expenseGraph = List.filled(4, 0.0);

        for (final item in incomeItems) {
          final dayDiff = _calendarDaysBetween(item.date, now);
          if (dayDiff >= 0 && dayDiff < 28) {
            final slotIndex = 3 - (dayDiff ~/ 7);
            incomeGraph[slotIndex] += item.amount;
          }
        }

        for (final item in expenseItems) {
          final dayDiff = _calendarDaysBetween(item.date, now);
          if (dayDiff >= 0 && dayDiff < 28) {
            final slotIndex = 3 - (dayDiff ~/ 7);
            expenseGraph[slotIndex] += item.amount;
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

      final moneyToCollect = orders.where((order) {
        final orderId = (order['id'] ?? order['_id'] ?? '').toString();
        // Never count another tailor's outsourced jobs towards customer Udhar to collect
        if (orderId.isNotEmpty && outsourcedOrderIds.contains(orderId)) {
          return false;
        }
        return true;
      }).fold<double>(0, (sum, order) {
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
    DateTime? dt;
    if (val is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(val);
    } else if (val is DateTime) {
      dt = val;
    } else {
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      final intVal = int.tryParse(str);
      if (intVal != null && str.length >= 10) {
        dt = DateTime.fromMillisecondsSinceEpoch(intVal);
      } else {
        dt = DateTime.tryParse(str);
      }
    }
    return dt?.toLocal();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _calendarDaysBetween(DateTime from, DateTime to) {
    final d1 = DateTime.utc(from.year, from.month, from.day);
    final d2 = DateTime.utc(to.year, to.month, to.day);
    return d2.difference(d1).inDays;
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
      appBar: const CustomAppBar(
        title: 'StitchCraft Dashboard',
        automaticallyImplyLeading: false,
      ),
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
                              Builder(
                                builder: (context) {
                                  final orderId = (_nextUpOrder!['id'] ?? '').toString();
                                  final displayId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
                                  final dueDate = _nextUpOrder!['due_date'] != null
                                      ? _nextUpOrder!['due_date'].toString().split('T').first
                                      : 'Today';
                                  return Text(
                                    'Order #$displayId • Due: $dueDate',
                                    style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
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
