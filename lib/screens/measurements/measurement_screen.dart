import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/measurement_model.dart';
import '../../models/customer_model.dart';
import '../../widgets/main_layout.dart';
import 'package:intl/intl.dart';

class MeasurementListScreen extends StatelessWidget {
  const MeasurementListScreen({super.key});

  void _addNewMeasurement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Client'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Customer>>(
            stream: DatabaseService().getCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Text('No clients found.'),
                     TextButton(
                       onPressed: () => Navigator.pushNamed(context, '/edit_client'),
                       child: const Text('Add Client'),
                     )
                   ],
                 );
              }
              
              final customers = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(customer.name[0])),
                    title: Text(customer.name),
                    subtitle: Text(customer.phone),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to Selector with Customer
                      Navigator.pushNamed(context, '/measurement_selector', arguments: customer);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return MainLayout(
      title: 'Measurements',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewMeasurement(context),
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder<List<Measurement>>(
        stream: db.getMeasurements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.straighten, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No measurements recorded yet.'),
                ],
              ),
            );
          }

          final measurements = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final m = measurements[index];
              final date = DateFormat('dd MMM yyyy').format(m.measurementDate);
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(Icons.accessibility, color: Colors.blue.shade700),
                  ),
                  title: Text(m.itemType),
                  subtitle: FutureBuilder<Customer?>(
                     future: db.getCustomerById(m.customerId),
                     builder: (context, snap) {
                        return Text('${snap.data?.name ?? "Unknown Client"} • $date');
                     },
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                      if (m.customerId.isNotEmpty) {
                         db.getCustomerById(m.customerId).then((c) {
                             if(c != null && context.mounted) {
                                Navigator.pushNamed(context, '/client_profile', arguments: c);
                             }
                         });
                      }
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
