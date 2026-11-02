import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/whatsapp_service.dart';

class UdharList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const UdharList({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter orders with outstanding balance
    final udharOrders = orders.where((o) {
      final total = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
      return (total - advance) > 0.01;
    }).toList();

    double totalUdhar = 0.0;
    for (final o in udharOrders) {
      final total = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
      final advance = (o['advance_amount'] as num?)?.toDouble() ?? 0.0;
      totalUdhar += (total - advance);
    }

    if (udharOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 56, color: AppTheme.trustGreen),
            const SizedBox(height: 12),
            Text(
              'No pending balances (Udhar)!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.trustGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All customer orders are fully paid up.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Udhar Summary Header Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.alertRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL UDHAR OUTSTANDING',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.alertRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${udharOrders.length} orders with balance',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkGrey),
                  ),
                ],
              ),
              Text(
                '₹${totalUdhar.toStringAsFixed(0)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.alertRed,
                ),
              ),
            ],
          ),
        ),

        // List of Udhar Orders
        ...udharOrders.map((order) {
          final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          final advance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
          final balance = total - advance;
          final customerName = order['customer_name']?.toString() ?? 'Customer';
          final orderId = order['id']?.toString().split('-').first.toUpperCase() ?? '';
          final phone = order['phone']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.safetyOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: AppTheme.safetyOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Order #$orderId',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.darkGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Due: ₹${balance.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.alertRed,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Paid: ₹${advance.toStringAsFixed(0)} / Total: ₹${total.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: AppTheme.darkGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        WhatsAppService().sendPaymentReminder(
                          phoneNumber: phone,
                          customerName: customerName,
                          orderId: orderId,
                          balanceAmount: balance,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.trustGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'Send WhatsApp Reminder',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

