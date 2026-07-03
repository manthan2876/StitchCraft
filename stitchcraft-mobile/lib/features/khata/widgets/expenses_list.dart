import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class ExpensesList extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const ExpensesList({
    super.key,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (expenses.isEmpty) {
      return Center(
        child: Text(
          'No expenses recorded yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final isPending = (expense['sync_status'] ?? 0) != 0;

        return NeoCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.alertRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_down, color: AppTheme.alertRed, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          expense['category'] ?? 'General',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.cloud_upload_outlined, size: 14, color: AppTheme.darkGrey),
                        ]
                      ],
                    ),
                    Text(
                      expense['description'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${expense['amount']}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.alertRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
