import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/features/khata/widgets/add_expense_bottom_sheet.dart';
import 'package:stitchcraft/features/khata/widgets/add_income_bottom_sheet.dart';
import 'package:stitchcraft/features/khata/widgets/expenses_list.dart';
import 'package:stitchcraft/features/khata/widgets/income_list.dart';
import 'package:stitchcraft/features/khata/widgets/udhar_list.dart';

import 'package:stitchcraft/core/widgets/custom_app_bar.dart';

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
  List<Map<String, dynamic>> _manualIncomes = [];
  List<Map<String, dynamic>> _paidOrders = [];
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData(showLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final allExpensesAndIncomes = await _localDb.getAllExpenses();
      final ordersList = await _localDb.getAllOrders();

      final actualExpenses = allExpensesAndIncomes.where((e) {
        final type = (e['type'] ?? '').toString().toLowerCase();
        final cat = (e['category'] ?? '').toString().toLowerCase();
        return type != 'income' && !cat.startsWith('income');
      }).toList();

      final manualIncomes = allExpensesAndIncomes.where((e) {
        final type = (e['type'] ?? '').toString().toLowerCase();
        final cat = (e['category'] ?? '').toString().toLowerCase();
        return type == 'income' || cat.startsWith('income');
      }).toList();

      // Only orders whose payment is done (full payment received and not cancelled)
      final paidOrders = ordersList.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled') return false;

        final total = (o['total_amount'] as num?)?.toDouble() ??
            (o['price'] as num?)?.toDouble() ??
            0.0;
        final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
        final balance = (total - advance).clamp(0.0, double.infinity);
        final paymentStatus = (o['payment_status'] ?? '').toString().toLowerCase();

        return (total > 0 && balance <= 0) || paymentStatus == 'paid';
      }).toList();

      if (mounted) {
        setState(() {
          _expenses = actualExpenses;
          _manualIncomes = manualIncomes;
          _paidOrders = paidOrders;
          _allOrders = ordersList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading ledger: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddExpenseModal() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddExpenseBottomSheet(
          onAddExpense: (newExpense) async {
            await _localDb.insertExpense(newExpense);
            _loadData(showLoading: false);
          },
        );
      },
    );
  }

  Future<void> _showAddIncomeModal() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddIncomeBottomSheet(
          onAddIncome: (newIncome) async {
            await _localDb.insertIncome(newIncome);
            _loadData(showLoading: false);
          },
        );
      },
    );
  }

  Future<void> _deleteManualIncome(String id) async {
    await _localDb.deleteIncome(id);
    _loadData(showLoading: false);
  }

  Future<void> _deleteExpense(String id) async {
    await _localDb.deleteExpense(id);
    _loadData(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.khata_ledger,
        automaticallyImplyLeading: !widget.isTab,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.isTab ? 72 : 0),
        child: _tabController.index == 1
            ? FloatingActionButton.extended(
                onPressed: _showAddIncomeModal,
                backgroundColor: AppTheme.trustGreen,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Record Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : _tabController.index == 2
                ? FloatingActionButton.extended(
                    onPressed: _showAddExpenseModal,
                    backgroundColor: AppTheme.brandPurple,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                UdharList(orders: _allOrders, isTab: widget.isTab, onRefresh: _loadData),
                IncomeList(
                  paidOrders: _paidOrders,
                  manualIncomes: _manualIncomes,
                  isTab: widget.isTab,
                  onRefresh: _loadData,
                  onDeleteManualIncome: _deleteManualIncome,
                  onAddManualIncome: _showAddIncomeModal,
                ),
                ExpensesList(
                  expenses: _expenses,
                  isTab: widget.isTab,
                  onRefresh: _loadData,
                  onDeleteExpense: _deleteExpense,
                  onAddExpense: _showAddExpenseModal,
                ),
              ],
            ),
    );
  }
}
