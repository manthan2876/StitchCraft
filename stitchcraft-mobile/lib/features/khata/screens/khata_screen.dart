import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/features/khata/widgets/add_expense_bottom_sheet.dart';
import 'package:stitchcraft/features/khata/widgets/expenses_list.dart';
import 'package:stitchcraft/features/khata/widgets/income_list.dart';

class KhataScreen extends StatefulWidget {
  final int initialTabIndex;
  const KhataScreen({super.key, this.initialTabIndex = 0});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}


class _KhataScreenState extends State<KhataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _localDb = LocalDatabaseService();
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
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
      appBar: AppBar(
        title: Text(context.loc.khata_ledger),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: AppTheme.brandPurple,
          unselectedLabelColor: AppTheme.darkGrey,
          tabs: [
            Tab(text: context.loc.expenses),
            Tab(text: context.loc.income),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseModal,
        backgroundColor: AppTheme.brandPurple,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ExpensesList(expenses: _expenses),
                IncomeList(orders: _orders),
              ],
            ),
    );
  }
}
