import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/customer_model.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/custom_text_field.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Customers',
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/edit_client'),
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder<List<Customer>>(
        stream: _dbService.getCustomers(),
        builder: (BuildContext context, AsyncSnapshot<List<Customer>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data!;
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.people_outline, size: 64, color: Theme.of(context).disabledColor),
                   const SizedBox(height: 16),
                   const Text('No customers found. Add one to get started!'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (BuildContext context, int index) {
              final customer = customers[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.name, 
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    customer.phone,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                        tooltip: 'Edit Customer',
                        onPressed: () => Navigator.pushNamed(context, '/edit_client', arguments: customer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                         tooltip: 'Delete Customer',
                        onPressed: () => _confirmDelete(context, customer),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to Client Profile
                    Navigator.pushNamed(context, '/client_profile', arguments: customer);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, Customer? customer) {
    final isEditing = customer != null;

    if (isEditing) {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Customer' : 'Add New Customer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Name', 
                  icon: Icons.person_outline,
                  controller: _nameController,
                ),
                CustomTextField(
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  
                ),
                CustomTextField(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final phone = _phoneController.text.trim();
                        final email = _emailController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a name')),
                          );
                          return;
                        }

                        try {
                          if (isEditing) {
                            final updatedCustomer = Customer(
                              id: customer.id,
                              name: name,
                              phone: phone,
                              email: email,
                            );
                            await _dbService.updateCustomer(updatedCustomer);
                            if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Customer updated successfully')),
                              );
                            }
                          } else {
                            final newCustomer = Customer(
                              id: '',
                              name: name,
                              phone: phone,
                              email: email,
                            );
                            await _dbService.addCustomer(newCustomer);
                             if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Customer added successfully')),
                              );
                             }
                          }
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      child: Text(isEditing ? 'Update' : 'Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? All associated orders and measurements will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbService.deleteCustomerAndRelatedData(customer.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                customer.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(customer.name, style: Theme.of(context).textTheme.headlineSmall),
             const SizedBox(height: 8),
             ListTile(
               leading: const Icon(Icons.phone_outlined),
               title: Text(customer.phone.isNotEmpty ? customer.phone : 'No Phone'),
             ),
             ListTile(
               leading: const Icon(Icons.email_outlined),
               title: Text(customer.email.isNotEmpty ? customer.email : 'No Email'),
             ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showForm(context, customer);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
