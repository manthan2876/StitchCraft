import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class IncomeList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const IncomeList({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No order payments recorded yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return NeoCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.trustGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up, color: AppTheme.trustGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customer_name'] ?? 'Walk-in Customer',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Order: ${order['id']?.toString().split('-').first.toUpperCase()}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order['total_amount']}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.trustGreen,
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
