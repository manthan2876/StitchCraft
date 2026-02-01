import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../models/measurement_model.dart';
import '../../services/database_service.dart';
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
          child: const Icon(Icons.add),
          tooltip: 'New Order',
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
             backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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
  final DatabaseService dbService; // Using correct model import via parent file
  
  const _HistoryTab({required this.customerId, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Order History (Integration Pending)"));
    // Note: To implement history, we need the Order model import here or generic,
    // but StreamBuilder<List<Order>> requires explicit import which matches main. dart type.
    // For now keeping simple text to avoid import conflicts until Order model is fully standardized.
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
