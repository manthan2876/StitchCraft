import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/models/customer_model.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/models/measurement_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:intl/intl.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final customer = ModalRoute.of(context)?.settings.arguments as Customer?;

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No customer data provided')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(customer.name),
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Personal Details'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushNamed(context, '/edit_client', arguments: customer),
            )
          ],
        ),
        body: TabBarView(
          children: [
            _PersonalDetailsTab(customer: customer, dbService: _dbService),
            _HistoryTab(customerId: customer.id, dbService: _dbService),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/order_wizard', arguments: customer), 
          tooltip: 'New Order',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _PersonalDetailsTab extends StatelessWidget {
  final Customer customer;
  final DatabaseService dbService;
  const _PersonalDetailsTab({required this.customer, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           CircleAvatar(
             radius: 50,
             backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
             child: Text(customer.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
           ),
           const SizedBox(height: 16),
           Text(customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
           Text(customer.phone, style: const TextStyle(color: Colors.grey)),
           if (customer.email.isNotEmpty) Text(customer.email, style: const TextStyle(color: Colors.grey)),
           const SizedBox(height: 24),
           
           _InfoCard(
             title: 'Notes', 
             content: 'No notes available.', // Notes field missing in model currently
             icon: Icons.note_alt_outlined,
           ),
           const SizedBox(height: 16),
           
           StreamBuilder<List<Measurement>>(
             stream: dbService.getMeasurementsByCustomerId(customer.id),
             builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final latest = snapshot.data!.first;
                  return _InfoCard(
                    title: 'Latest Measurements',
                    content: '${latest.itemType} - ${DateFormat('d MMM yyyy').format(latest.measurementDate)}',
                    icon: Icons.straighten,
                    action: 'View All',
                    onAction: () {
                         // Simplify: Just navigate to selector for now, or build a list view
                         Navigator.pushNamed(context, '/measurement_selector', arguments: customer);
                    },
                  );
                }
                return _InfoCard(
                  title: 'Measurements',
                  content: 'No measurements recorded.',
                  icon: Icons.straighten,
                  action: 'Add',
                  onAction: () => Navigator.pushNamed(context, '/measurement_selector', arguments: customer),
                );
             },
           ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String customerId;
  final DatabaseService dbService;
  
  const _HistoryTab({required this.customerId, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: dbService.getOrdersByCustomerId(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No order history yet."));
        }

        final orders = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.pushNamed(context, '/add_edit_order', arguments: order);
                },
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(
                  order.itemTypes.join(', ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price: ₹${order.totalAmount} | Profit: ₹${order.profit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: order.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Status: ${order.status}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  
  const _InfoCard({required this.title, required this.content, required this.icon, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
