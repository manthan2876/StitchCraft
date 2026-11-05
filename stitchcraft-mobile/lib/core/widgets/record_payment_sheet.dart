import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/utils/currency_utils.dart';

class PaymentResult {
  final double amount;
  final String method; // 'cash' or 'online'

  PaymentResult({
    required this.amount,
    required this.method,
  });
}

class RecordPaymentSheet extends StatefulWidget {
  final String customerName;
  final double balance;

  const RecordPaymentSheet({
    super.key,
    required this.customerName,
    required this.balance,
  });

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late final TextEditingController _amountController;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.balance > 0 ? widget.balance.toStringAsFixed(0) : '';
    _amountController = TextEditingController(text: defaultAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final normalized = _paymentMethod.toLowerCase() == 'online' || _paymentMethod.toLowerCase() == 'upi'
        ? 'UPI'
        : (_paymentMethod.toLowerCase() == 'cash' ? 'Cash' : _paymentMethod);

    Navigator.of(context).pop(PaymentResult(amount: amt, method: normalized));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.trustGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment, color: AppTheme.trustGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collect Payment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.customerName,
                        style: const TextStyle(color: AppTheme.darkGrey, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.alertRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.alertRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Outstanding Balance:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    CurrencyUtils.formatINR(widget.balance),
                    style: const TextStyle(
                      color: AppTheme.alertRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹) *',
                prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.trustGreen),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _paymentMethod == 'Cash',
                  onSelected: (val) {
                    if (val) setState(() => _paymentMethod = 'Cash');
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('UPI / Online'),
                  selected: _paymentMethod == 'UPI',
                  onSelected: (val) {
                    if (val) setState(() => _paymentMethod = 'UPI');
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.trustGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.check, size: 20),
                label: const Text(
                  'Confirm Payment',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

