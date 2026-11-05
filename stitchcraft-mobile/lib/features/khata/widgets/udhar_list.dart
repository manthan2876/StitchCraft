import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/core/services/whatsapp_service.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/widgets/record_payment_sheet.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

    final result = await showModalBottomSheet<PaymentResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RecordPaymentSheet(
        customerName: customerName,
        balance: balance,
      ),
    );

    if (result == null || result.amount <= 0) return;

    try {
      final normalizedMethod = result.method.toLowerCase() == 'online' || result.method.toLowerCase() == 'upi'
          ? 'UPI'
          : (result.method.toLowerCase() == 'cash' ? 'Cash' : result.method);

      // 1. Update local database
      final currentAdvance = (order['advance_amount'] as num?)?.toDouble() ?? 0.0;
      final newAdvance = currentAdvance + result.amount;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await LocalDatabaseService().updateRecord('orders', orderId, {
        'advance_amount': newAdvance,
        'payment_method': normalizedMethod,
        'sync_status': 3,
        'updated_at': nowMs,
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final shopId = prefs.getString('shopId');
        await LocalDatabaseService().insertPayment({
          'id': const Uuid().v4(),
          'order_id': orderId,
          'amount': result.amount,
          'payment_method': normalizedMethod,
          'date': nowMs,
          'shop_id': shopId,
          'sync_status': 1,
          'updated_at': nowMs,
        });
        DatabaseService.orderSignal.add(null);
      } catch (e) {
        debugPrint('Udhar payment insert error: $e');
      }

      // 2. Push to server if online
      final token = await AuthService().getToken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('${AuthService.baseUrl}/orders/$orderId/payments'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'amount': result.amount,
              'paymentType': normalizedMethod,
            }),
          ).timeout(const Duration(seconds: 10));
        } catch (netErr) {
          // Handled offline-first; will sync later
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${CurrencyUtils.formatINR(result.amount)} recorded!'),
            backgroundColor: AppTheme.trustGreen,
          ),
        );
        onRefresh?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally: $e'),
            backgroundColor: AppTheme.warmAmber,
          ),
        );
        onRefresh?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter orders with outstanding balance, strictly excluding outsourced partner jobs
    final udharOrders = orders.where((o) {
      final bool isPartnerJob = o['isPartnerJob'] == true ||
          o['isOutsourcedToMe'] == true ||
          (o['origin_shop_name'] != null && o['origin_shop_name'].toString().isNotEmpty) ||
          (o['delegation_status'] == 'assigned' && o['origin_shop_name'] != null);
      if (isPartnerJob) return false;

      final status = (o['status'] ?? '').toString().toLowerCase();
      if (status == 'cancelled') return false;

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

