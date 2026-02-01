import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Invoices')),
      body: StreamBuilder<List<Order>>(
        stream: DatabaseService().getOrders(),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           
           final orders = snapshot.data!;
           if (orders.isEmpty) return const Center(child: Text("No invoices yet"));

           return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Assuming 'Completed' or 'Delivered' means paid for now, or all orders generate invoice
              final isPaid = order.status == 'Delivered';
              
              return Card(
                 elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('Invoice #${order.id.substring(0,4)}'),
                  subtitle: Text(order.customerName),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
