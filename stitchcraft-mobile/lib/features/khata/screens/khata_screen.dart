import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/features/khata/widgets/add_expense_bottom_sheet.dart';
import 'package:stitchcraft/features/khata/widgets/expenses_list.dart';
import 'package:stitchcraft/features/khata/widgets/income_list.dart';
import 'package:stitchcraft/features/khata/widgets/udhar_list.dart';

import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class KhataScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool isTab;
  const KhataScreen({super.key, this.initialTabIndex = 0, this.isTab = false});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expensesList = await _localDb.getAllExpenses();
      final ordersList = await _localDb.getAllOrders();
      setState(() {
        _expenses = expensesList;
        _orders = ordersList;
      });
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddExpenseModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddExpenseBottomSheet(
          onAddExpense: (newExpense) async {
            await _localDb.insertExpense(newExpense);
            _loadData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.khata_ledger,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          indicatorColor: AppTheme.brandPurple,
          unselectedLabelColor: AppTheme.darkGrey,
          tabs: [
            Tab(text: context.loc.udhar_ledger),
            Tab(text: context.loc.income),
            Tab(text: context.loc.expenses),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: widget.isTab
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddExpenseModal,
              backgroundColor: AppTheme.brandPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                UdharList(orders: _orders, isTab: widget.isTab, onRefresh: _loadData),
                IncomeList(orders: _orders, isTab: widget.isTab),
                ExpensesList(expenses: _expenses, isTab: widget.isTab),
              ],
            ),
    );
  }

  double get _outstandingAmount => _orders.fold<double>(0, (total, order) {
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final paid = (order['advance_amount'] as num?)?.toDouble() ?? 0;
    return total + (amount - paid).clamp(0, double.infinity);
  });
}
