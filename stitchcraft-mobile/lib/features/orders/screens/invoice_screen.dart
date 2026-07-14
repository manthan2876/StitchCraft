import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Invoices')),
      body: StreamBuilder<List<Order>>(
        stream: DatabaseService().getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Text(
                "No invoices yet.",
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isPaid = order.status.toLowerCase() == 'delivered';
              
              return NeoCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(4),
                  onTap: () {
                    Navigator.pushNamed(context, '/invoice_details', arguments: order.id);
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.15),
                    child: const Icon(Icons.receipt_long, color: AppTheme.brandPurple),
                  ),
                  title: Text(
                    'Invoice #${order.id.substring(0, order.id.length > 4 ? 4 : order.id.length).toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    order.customerName,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isPaid ? AppTheme.trustGreen : AppTheme.safetyOrange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? AppTheme.trustGreen : AppTheme.safetyOrange,
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
