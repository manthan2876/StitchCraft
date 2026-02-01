import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stitchcraft/models/order_model.dart';
import 'package:stitchcraft/services/database_service.dart';
import 'package:stitchcraft/screens/orders/add_edit_order_screen.dart';
import '../../widgets/main_layout.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService().deleteOrder(orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Orders',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/order_wizard');
        },
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder<List<Order>>(
        stream: DatabaseService().getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.shopping_bag_outlined, size: 64, color: Theme.of(context).disabledColor),
                   const SizedBox(height: 16),
                   const Text('No orders found. Add one!'),
                ],
              ),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.checkroom,
                      color: Theme.of(context).primaryColor,
                      semanticLabel: 'Order Item',
                    ),
                  ),
                  title: Text(
                    order.itemTypes.isNotEmpty
                        ? order.itemTypes.join(', ').toUpperCase()
                        : 'NO ITEMS',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Due: ${order.dueDate != null ? DateFormat('MMM dd').format(order.dueDate!) : 'None'}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: order.status == 'Pending' ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: TextStyle(
                              color: order.status == 'Pending'
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                        tooltip: 'Edit Order',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditOrderScreen(order: order),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'Delete Order',
                        onPressed: () => _confirmDelete(context, order.id),
                      ),
                    ],
                  ),
                  onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditOrderScreen(order: order),
                        ),
                      );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
