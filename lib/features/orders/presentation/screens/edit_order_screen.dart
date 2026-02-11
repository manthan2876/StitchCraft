import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/models/order_model.dart' as order_model;
import 'package:stitchcraft/core/models/customer_model.dart';

class EditOrderScreen extends StatefulWidget {
  final order_model.Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _itemTypesController;

  Customer? _selectedCustomer;
  late String _selectedStatus;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.order.description,
    );
    _amountController = TextEditingController(
      text: widget.order.totalAmount.toString(),
    );
    _itemTypesController = TextEditingController(
      text: widget.order.itemTypes.join(', '),
    );
    _selectedStatus = widget.order.status;
    _dueDate = widget.order.dueDate;
    // Note: _selectedCustomer remains null until customer list is loaded
    // It will be populated from the StreamBuilder with customer matching the order's customerId
  }

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
      appBar: AppBar(
        title: const Text('Edit Order'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Order',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade200,
                child: const Icon(
                  Icons.shopping_bag,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Customer Selection
              StreamBuilder<List<Customer>>(
                stream: _dbService.getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = snapshot.data!;

                  // Auto-select the customer if not yet selected
                  if (_selectedCustomer == null && customers.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final customer = customers.firstWhere(
                        (c) => c.id == widget.order.customerId,
                        orElse: () => customers.first,
                      );
                      if (mounted) {
                        setState(() => _selectedCustomer = customer);
                      }
                    });
                  }

                  return DropdownButtonFormField<Customer>(
                    initialValue: _selectedCustomer,
                    hint: const Text('Select Customer'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Order Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemTypesController,
                decoration: InputDecoration(
                  labelText: 'Item Types (comma separated)',
                  prefixIcon: const Icon(Icons.format_list_bulleted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              // Due Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _isLoading ? null : _pickDueDate,
              ),
              const SizedBox(height: 16),
              // Status Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateOrder,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Update Order',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final itemTypes = _itemTypesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedOrder = widget.order.copyWith(
        description: _descriptionController.text.trim(),
        totalAmount: double.parse(_amountController.text),
        itemTypes: itemTypes,
        status: _selectedStatus,
        dueDate: _dueDate,
      );

      await _dbService.updateOrder(updatedOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
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
              Navigator.pop(context);
              await _deleteOrder();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder() async {
    setState(() => _isLoading = true);

    try {
      await _dbService.deleteOrder(widget.order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
