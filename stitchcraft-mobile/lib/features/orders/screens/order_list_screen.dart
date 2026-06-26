import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class OrderListScreen extends StatelessWidget {
  final String title;
  final String statusFilter; // 'pending', 'completed', 'all'

  const OrderListScreen({
    super.key,
    this.title = 'Orders',
    this.statusFilter = 'all',
  });

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> orders = [
      {'id': '#101', 'name': 'Ramesh Bhai', 'item': 'Shirt x 2', 'status': 'Pending', 'date': 'Today'},
      {'id': '#102', 'name': 'Sita Ben', 'item': 'Blouse', 'status': 'Ready', 'date': 'Yesterday'},
      {'id': '#103', 'name': 'Gopal', 'item': 'Pant', 'status': 'Delivered', 'date': '10 Feb'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return NeoCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.navyBlue.withValues(alpha: 0.1),
                child: Text(order['id'].toString().substring(1), style: const TextStyle(color: AppTheme.navyBlue, fontSize: 12)),
              ),
              title: Text(order['name'], style: AppTheme.masterjiTheme.textTheme.titleMedium),
              subtitle: Text('${order['item']} • ${order['date']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(order['status'])),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    color: _getStatusColor(order['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {
                // Open Order Details
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Ready': return AppTheme.emerald;
      case 'Delivered': return AppTheme.navyBlue;
      default: return Colors.grey;
    }
  }
}
