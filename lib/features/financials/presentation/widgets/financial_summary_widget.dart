import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/order_model.dart';

class FinancialSummaryWidget extends StatelessWidget {
  final Order order;

  const FinancialSummaryWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Costing Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRow('Selling Price', '₹${order.totalAmount.toStringAsFixed(2)}', isBold: true),
            const Divider(height: 24),
            _buildRow('Labor Cost', '₹${order.laborCost.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildRow('Material Cost', '₹${order.materialCost.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildRow('Overhead Cost', '₹${order.overheadCost.toStringAsFixed(2)}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Profit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${order.profit.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: order.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
