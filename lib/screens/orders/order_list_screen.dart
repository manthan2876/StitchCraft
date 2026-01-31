import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart' as order_model;
import '../../models/customer_model.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemTypesController = TextEditingController();

  Customer? _selectedCustomer;
  String _selectedStatus = 'pending';
  DateTime? _dueDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _itemTypesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders'), elevation: 0),
      body: StreamBuilder<List<order_model.Order>>(
        stream: _dbService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders found. Create one to get started!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusColor = _getStatusColor(order.status);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                  ),
                  subtitle: Text(
                    '${order.customerName} - ${order.description}',
                  ),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showForm(context, order),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, order),
                      ),
                    ],
                  ),
                  onTap: () => _showOrderDetails(context, order),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        tooltip: 'New Order',
        child: const Icon(Icons.add),
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

  void _showForm(BuildContext context, order_model.Order? order) {
    final isEditing = order != null;

    if (isEditing) {
      _descriptionController.text = order.description;
      _amountController.text = order.totalAmount.toString();
      _itemTypesController.text = order.itemTypes.join(', ');
      _selectedStatus = order.status;
      _dueDate = order.dueDate;
      _selectedCustomer = null; // Would be loaded from database if needed
    } else {
      _descriptionController.clear();
      _amountController.clear();
      _itemTypesController.clear();
      _selectedStatus = 'pending';
      _dueDate = null;
      _selectedCustomer = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Order' : 'Create New Order',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Customer Selection
                StreamBuilder<List<Customer>>(
                  stream: _dbService.getCustomers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final customers = snapshot.data!;
                    return DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      hint: const Text('Select Customer'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: customers
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCustomer = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a customer' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemTypesController,
                  decoration: InputDecoration(
                    labelText: 'Item Types (comma separated)',
                    hintText: 'e.g., shirt, pants, dress',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Total Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Due Date Picker
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'No due date selected'
                            : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _dueDate = date);
                        }
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Delivered'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_selectedCustomer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a customer'),
                            ),
                          );
                          return;
                        }

                        final description = _descriptionController.text.trim();
                        final amountStr = _amountController.text.trim();
                        final itemTypes = _itemTypesController.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();

                        if (description.isEmpty || amountStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all required fields'),
                            ),
                          );
                          return;
                        }

                        try {
                          final amount = double.parse(amountStr);

                          if (isEditing) {
                            final updatedOrder = order.copyWith(
                              description: description,
                              totalAmount: amount,
                              itemTypes: itemTypes,
                              status: _selectedStatus,
                              dueDate: _dueDate,
                            );
                            await _dbService.updateOrder(updatedOrder);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order updated successfully'),
                              ),
                            );
                          } else {
                            final newOrder = order_model.Order(
                              id: '',
                              customerId: _selectedCustomer!.id,
                              customerName: _selectedCustomer!.name,
                              orderDate: DateTime.now(),
                              dueDate: _dueDate,
                              status: _selectedStatus,
                              totalAmount: amount,
                              description: description,
                              itemTypes: itemTypes,
                              measurements: {},
                            );
                            await _dbService.addOrder(newOrder);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order created successfully'),
                              ),
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, order_model.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbService.deleteOrder(order.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, order_model.Order order) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Order ID:',
              order.id.substring(0, 8).toUpperCase(),
            ),
            _buildDetailRow('Customer:', order.customerName),
            _buildDetailRow('Status:', order.status.toUpperCase()),
            _buildDetailRow(
              'Amount:',
              '\$${order.totalAmount.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Description:', order.description),
            _buildDetailRow('Items:', order.itemTypes.join(', ')),
            _buildDetailRow(
              'Order Date:',
              order.orderDate.toLocal().toString().split(' ')[0],
            ),
            if (order.dueDate != null)
              _buildDetailRow(
                'Due Date:',
                order.dueDate!.toLocal().toString().split(' ')[0],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showForm(context, order);
                  },
                  child: const Text('Edit'),
                ),
                ElevatedButton(
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
