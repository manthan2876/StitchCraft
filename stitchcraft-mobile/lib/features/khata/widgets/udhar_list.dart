import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/whatsapp_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UdharList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool isTab;
  final VoidCallback? onRefresh;

  const UdharList({
    super.key,
    required this.orders,
    this.isTab = false,
    this.onRefresh,
  });

  Future<void> _showRecordPaymentDialog(
    BuildContext context,
    Map<String, dynamic> order,
    double balance,
  ) async {
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final customerName = order['customer_name']?.toString() ?? 'Customer';
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    String paymentMethod = 'cash';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment for $customerName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Outstanding Balance: ${CurrencyUtils.formatINR(balance)}',
                style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Received (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Cash'),
                    selected: paymentMethod == 'cash',
                    onSelected: (val) => setModalState(() => paymentMethod = 'cash'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('UPI / Online'),
                    selected: paymentMethod == 'online',
                    onSelected: (val) => setModalState(() => paymentMethod = 'online'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.trustGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final entered = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (entered <= 0) return;
                    Navigator.pop(ctx);

                    try {
                      // 1. Update local database
                      final currentAdvance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
                      final newAdvance = currentAdvance + entered;
                      await LocalDatabaseService().updateRecord('orders', orderId, {
                        'advance_amount': newAdvance,
                        'sync_status': 3,
                        'updated_at': DateTime.now().millisecondsSinceEpoch,
                      });

                      // 2. Push to server if online
                      final token = await AuthService().getToken();
                      if (token != null) {
                        await http.post(
                          Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: json.encode({
                            'amount': entered,
                            'paymentType': paymentMethod,
                          }),
                        );
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment of ${CurrencyUtils.formatINR(entered)} recorded!'),
                            backgroundColor: AppTheme.trustGreen,
                          ),
                        );
                      }
                      onRefresh?.call();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved locally: $e'),
                            backgroundColor: AppTheme.warmAmber,
                          ),
                        );
                      }
                      onRefresh?.call();
                    }
                  },
                  child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amountController.dispose();
  }

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
              context.loc.no_udhar_balances,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.trustGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.loc.all_orders_paid,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isTab ? 96 : 24),
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
                    context.loc.total_udhar_outstanding,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.alertRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${udharOrders.length} ${context.loc.orders_with_balance}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.darkGrey),
                  ),
                ],
              ),
              Text(
                CurrencyUtils.formatINR(totalUdhar, showDecimals: false),
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
          final phone = (order['phone']?.toString().isNotEmpty == true
                  ? order['phone']
                  : order['customer_phone'])
              ?.toString() ??
              '';

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
                              '${context.loc.order_num}$orderId',
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
                            '${context.loc.due_amount}: ${CurrencyUtils.formatINR(balance, showDecimals: false)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.alertRed,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${context.loc.paid_amount}: ${CurrencyUtils.formatINR(advance, showDecimals: false)} / ${context.loc.total_amount}: ${CurrencyUtils.formatINR(total, showDecimals: false)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: AppTheme.darkGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Secondary: WhatsApp reminder
                      IconButton(
                        tooltip: context.loc.send_whatsapp_reminder,
                        icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.trustGreen, size: 22),
                        onPressed: () {
                          if (phone.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No phone number saved for this customer.'),
                                backgroundColor: AppTheme.alertRed,
                              ),
                            );
                            return;
                          }
                          WhatsAppService().sendPaymentReminder(
                            phoneNumber: phone,
                            customerName: customerName,
                            orderId: orderId,
                            balanceAmount: balance,
                          );
                        },
                      ),
                      // Primary: Record Payment
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.trustGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showRecordPaymentDialog(context, order, balance),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(
                          context.loc.record_payment,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

