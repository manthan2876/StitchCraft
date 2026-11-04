import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:intl/intl.dart';

class IncomeList extends StatefulWidget {
  final List<Map<String, dynamic>> paidOrders;
  final List<Map<String, dynamic>> manualIncomes;
  final bool isTab;
  final VoidCallback? onRefresh;
  final Function(String id)? onDeleteManualIncome;
  final VoidCallback? onAddManualIncome;

  const IncomeList({
    super.key,
    required this.paidOrders,
    required this.manualIncomes,
    this.isTab = false,
    this.onRefresh,
    this.onDeleteManualIncome,
    this.onAddManualIncome,
  });

  @override
  State<IncomeList> createState() => _IncomeListState();
}

class _IncomeListState extends State<IncomeList> {
  String _filter = 'all'; // 'all', 'orders', 'manual'

  DateTime _resolveDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    DateTime dt;
    if (dateVal is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(dateVal);
    } else if (dateVal is DateTime) {
      dt = dateVal;
    } else if (dateVal is String) {
      final parsed = DateTime.tryParse(dateVal);
      if (parsed != null) {
        dt = parsed;
      } else {
        final asInt = int.tryParse(dateVal);
        dt = asInt != null ? DateTime.fromMillisecondsSinceEpoch(asInt) : DateTime.now();
      }
    } else {
      dt = DateTime.now();
    }
    return dt.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build unified income entries
    final List<Map<String, dynamic>> unifiedEntries = [];

    // 1. Add Paid Orders
    for (final order in widget.paidOrders) {
      final total = (order['total_amount'] as num?)?.toDouble() ??
          (order['price'] as num?)?.toDouble() ??
          0.0;
      final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
      final effectiveAmount = advance > 0 ? advance : total;
      final orderDate = _resolveDate(order['order_date']);
      final updateDate = order['updated_at'] != null ? _resolveDate(order['updated_at']) : null;
      DateTime date = orderDate;
      if (updateDate != null && updateDate.isAfter(orderDate)) {
        date = updateDate;
      }
      final id = (order['id'] ?? order['_id'] ?? '').toString();
      final displayId = id.length > 8 ? id.substring(0, 8) : id;
      final customer = (order['customer_name'] ?? 'Walk-in Customer').toString();
      final garment = (order['garment_type'] ?? order['apparelType'] ?? '').toString();

      unifiedEntries.add({
        'id': id,
        'displayId': displayId,
        'title': garment.isNotEmpty ? '$customer • $garment' : customer,
        'subtitle': 'Order #$displayId • Paid in Full',
        'amount': effectiveAmount,
        'date': date,
        'isOrder': true,
        'rawData': order,
      });
    }

    // 2. Add Manual Income entries
    for (final manual in widget.manualIncomes) {
      final amt = (manual['amount'] as num?)?.toDouble() ?? 0.0;
      final date = _resolveDate(manual['date'] ?? manual['updated_at']);
      final rawCat = (manual['category'] ?? 'General Income').toString();
      final category = rawCat.startsWith('Income: ') ? rawCat.substring(8) : rawCat;
      final desc = (manual['description'] ?? '').toString();
      final id = (manual['id'] ?? '').toString();

      unifiedEntries.add({
        'id': id,
        'displayId': id.length > 8 ? id.substring(0, 8) : id,
        'title': category,
        'subtitle': desc.isNotEmpty ? '$desc • Manual Entry' : 'Manual Income Entry',
        'amount': amt,
        'date': date,
        'isOrder': false,
        'rawData': manual,
      });
    }

    // Sort descending by date
    unifiedEntries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Apply active filter
    final filteredEntries = unifiedEntries.where((e) {
      if (_filter == 'orders') return e['isOrder'] == true;
      if (_filter == 'manual') return e['isOrder'] == false;
      return true;
    }).toList();

    // Summary calculations
    final totalIncome = unifiedEntries.fold<double>(0.0, (sum, e) => sum + (e['amount'] as double));
    final ordersTotal = widget.paidOrders.fold<double>(0.0, (sum, o) {
      final total = (o['total_amount'] as num?)?.toDouble() ?? (o['price'] as num?)?.toDouble() ?? 0.0;
      return sum + total;
    });
    final manualTotal = widget.manualIncomes.fold<double>(
      0.0,
      (sum, m) => sum + ((m['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      color: AppTheme.trustGreen,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isTab ? 96 : 32),
        children: [
          // Total Income Summary Card
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
                      'Total Earned Income',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.trustGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppTheme.trustGreen),
                          SizedBox(width: 4),
                          Text(
                            'Paid Only',
                            style: TextStyle(
                              color: AppTheme.trustGreen,
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
                  CurrencyUtils.formatINR(totalIncome),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.trustGreen,
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
                          Text(
                            'From Paid Orders',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.formatINR(ordersTotal, showDecimals: false),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${widget.paidOrders.length} completed',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 11),
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
                          Text(
                            'From Manual Entries',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.formatINR(manualTotal, showDecimals: false),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${widget.manualIncomes.length} records',
                            style: TextStyle(color: AppTheme.darkGrey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Segmented Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All (${unifiedEntries.length})'),
                const SizedBox(width: 8),
                _filterChip('orders', 'Paid Orders (${widget.paidOrders.length})'),
                const SizedBox(width: 8),
                _filterChip('manual', 'Manual (${widget.manualIncomes.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Income List Items or Empty State
          if (filteredEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppTheme.darkGrey.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No income records found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _filter == 'orders'
                          ? 'Orders will appear here once full payment is received.'
                          : 'Use "Record Income" to log manual tailoring or alteration earnings.',
                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.onAddManualIncome != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.trustGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: widget.onAddManualIncome,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Record Income'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...filteredEntries.map((entry) {
              final isOrder = entry['isOrder'] as bool;
              final amount = entry['amount'] as double;
              final date = entry['date'] as DateTime;
              final formattedDate = DateFormat('dd MMM, yyyy').format(date);

              return NeoCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: isOrder
                      ? () {
                          Navigator.pushNamed(
                            context,
                            '/order_details',
                            arguments: entry['id'],
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isOrder ? AppTheme.trustGreen : AppTheme.brandPurple).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOrder ? Icons.check_circle : Icons.account_balance_wallet,
                          color: isOrder ? AppTheme.trustGreen : AppTheme.brandPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry['title'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${entry['subtitle']} • $formattedDate',
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
                            '+${CurrencyUtils.formatINR(amount)}',
                            style: const TextStyle(
                              color: AppTheme.trustGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (!isOrder && widget.onDeleteManualIncome != null) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _confirmDeleteManual(context, entry['id'] as String),
                              child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.darkGrey),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
      selectedColor: AppTheme.trustGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.trustGreen : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Future<void> _confirmDeleteManual(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income Entry?'),
        content: const Text('Are you sure you want to remove this manual income record?'),
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
      widget.onDeleteManualIncome?.call(id);
    }
  }
}
