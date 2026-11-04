import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:intl/intl.dart';

class ExpensesList extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  final bool isTab;
  final VoidCallback? onRefresh;
  final Function(String id)? onDeleteExpense;
  final VoidCallback? onAddExpense;

  const ExpensesList({
    super.key,
    required this.expenses,
    this.isTab = false,
    this.onRefresh,
    this.onDeleteExpense,
    this.onAddExpense,
  });

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  String _filter = 'all';

  DateTime _resolveDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is int) return DateTime.fromMillisecondsSinceEpoch(dateVal);
    if (dateVal is DateTime) return dateVal;
    if (dateVal is String) {
      final parsed = DateTime.tryParse(dateVal);
      if (parsed != null) return parsed;
      final asInt = int.tryParse(dateVal);
      if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.now();
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('fabric') || lower.contains('material') || lower.contains('cloth')) {
      return Icons.shopping_bag_outlined;
    } else if (lower.contains('rent') || lower.contains('shop') || lower.contains('room')) {
      return Icons.home_work_outlined;
    } else if (lower.contains('salary') || lower.contains('karigar') || lower.contains('wage') || lower.contains('staff')) {
      return Icons.people_outline;
    } else if (lower.contains('electricity') || lower.contains('power') || lower.contains('bill') || lower.contains('util')) {
      return Icons.bolt_outlined;
    } else if (lower.contains('machine') || lower.contains('repair') || lower.contains('service')) {
      return Icons.build_outlined;
    } else if (lower.contains('thread') || lower.contains('button') || lower.contains('zip')) {
      return Icons.content_cut_outlined;
    } else if (lower.contains('tea') || lower.contains('snack') || lower.contains('food')) {
      return Icons.local_cafe_outlined;
    }
    return Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out manual income records if any slipped into expenses table
    final pureExpenses = widget.expenses.where((e) {
      final type = (e['type'] ?? '').toString().toLowerCase();
      final cat = (e['category'] ?? '').toString().toLowerCase();
      return type != 'income' && !cat.startsWith('income');
    }).toList();

    // Sort descending by date
    pureExpenses.sort((a, b) {
      final dateA = _resolveDate(a['date'] ?? a['updated_at']);
      final dateB = _resolveDate(b['date'] ?? b['updated_at']);
      return dateB.compareTo(dateA);
    });

    // Detect distinct categories for filter chips
    final Set<String> distinctCategories = {};
    for (final e in pureExpenses) {
      final cat = (e['category'] ?? 'General').toString().trim();
      if (cat.isNotEmpty) distinctCategories.add(cat);
    }

    // Apply active category filter
    final filteredExpenses = pureExpenses.where((e) {
      if (_filter == 'all') return true;
      final cat = (e['category'] ?? 'General').toString().trim().toLowerCase();
      return cat == _filter.toLowerCase();
    }).toList();

    // Summary calculations
    final totalExpenses = pureExpenses.fold<double>(
      0.0,
      (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      color: AppTheme.alertRed,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isTab ? 96 : 32),
        children: [
          // Total Expense Summary Card
          NeoCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Shop Expenses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_down, size: 14, color: AppTheme.alertRed),
                          SizedBox(width: 4),
                          Text(
                            'Recorded',
                            style: TextStyle(
                              color: AppTheme.alertRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatINR(totalExpenses),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.alertRed,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Transactions',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pureExpenses.length} entries',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: theme.dividerColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${distinctCategories.length} active',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Filter Chips
          if (distinctCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All (${pureExpenses.length})'),
                    ...distinctCategories.map((cat) {
                      final count = pureExpenses.where((e) => (e['category'] ?? '').toString().trim().toLowerCase() == cat.toLowerCase()).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _filterChip(cat, '$cat ($count)'),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Expense List Items or Empty State
          if (filteredExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.darkGrey.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No expense records found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use "Add Expense" to record workshop materials, rent, or maintenance costs.',
                      style: TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onAddExpense != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: widget.onAddExpense,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Expense'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...filteredExpenses.map((expense) {
              final id = (expense['id'] ?? expense['_id'] ?? '').toString();
              final category = (expense['category'] ?? 'General').toString();
              final desc = (expense['description'] ?? '').toString();
              final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
              final date = _resolveDate(expense['date'] ?? expense['updated_at']);
              final formattedDate = DateFormat('dd MMM, yyyy').format(date);
              final isPending = (expense['sync_status'] ?? 0) != 0;

              return NeoCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: AppTheme.alertRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (isPending) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.cloud_upload_outlined, size: 14, color: AppTheme.darkGrey),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            desc.isNotEmpty ? '$desc • $formattedDate' : formattedDate,
                            style: const TextStyle(
                              color: AppTheme.darkGrey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${CurrencyUtils.formatINR(amount)}',
                          style: const TextStyle(
                            color: AppTheme.alertRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.onDeleteExpense != null && id.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _confirmDeleteExpense(context, id, category),
                            child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.darkGrey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filter.toLowerCase() == key.toLowerCase();
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
      selectedColor: AppTheme.brandPurple.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brandPurple : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Future<void> _confirmDeleteExpense(BuildContext context, String id, String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete this "$category" expense entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDeleteExpense?.call(id);
    }
  }
}
