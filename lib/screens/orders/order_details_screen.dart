import 'package:flutter/material.dart';
import '../../models/order_model.dart' as order_model;

class OrderDetailsScreen extends StatelessWidget {
  final order_model.Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green.shade200,
                child: const Icon(
                  Icons.shopping_bag,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildDetailCard(
              icon: Icons.person,
              label: 'Customer',
              value: order.customerName,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.description,
              label: 'Description',
              value: order.description,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.attach_money,
              label: 'Total Amount',
              value: '\$${order.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.calendar_today,
              label: 'Order Date',
              value: order.orderDate.toLocal().toString().split(' ')[0],
            ),
            if (order.dueDate != null)
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.calendar_month,
                    label: 'Due Date',
                    value: order.dueDate!.toLocal().toString().split(' ')[0],
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.shopping_cart,
              label: 'Item Types',
              value: order.itemTypes.isNotEmpty
                  ? order.itemTypes.join(', ')
                  : 'None',
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Icons.badge,
              label: 'Order ID',
              value: order.id,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
