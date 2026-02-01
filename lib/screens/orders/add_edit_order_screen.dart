import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:stitchcraft/models/order_model.dart';
import 'package:stitchcraft/services/database_service.dart';
import '../../widgets/main_layout.dart';

class AddEditOrderScreen extends StatefulWidget {
  final Order? order; // If null, it's Add mode. If exists, Edit mode.

  const AddEditOrderScreen({super.key, this.order});

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _itemTypeController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'Pending';

  final List<String> _statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
    'Delivered',
  ];
  
  // Lab 7: New state variables
  bool _isRush = false;
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.order?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.order?.totalAmount.toString() ?? '',
    );
    _itemTypeController = TextEditingController(
      text: (widget.order?.itemTypes.isNotEmpty == true) 
          ? widget.order!.itemTypes.first 
          : '',
    );
    if (widget.order != null) {
      _selectedDate = widget.order!.dueDate ?? DateTime.now();
      _status = widget.order!.status;
      _isRush = widget.order!.isRush;
      _paymentMethod = widget.order!.paymentMethod;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _itemTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      final order = Order(
        id: widget.order?.id ?? '', 
        customerId: widget.order?.customerId ?? 'temp_customer_id',
        customerName: widget.order?.customerName ?? 'Unknown',
        description: _descriptionController.text.trim(),
        itemTypes: [_itemTypeController.text.trim()],
        totalAmount: double.parse(_amountController.text.trim()),
        dueDate: _selectedDate,
        status: _status,
        orderDate: widget.order?.orderDate ?? DateTime.now(),
        measurements: widget.order?.measurements ?? {},
        isRush: _isRush,
        paymentMethod: _paymentMethod,
      );

      try {
        if (widget.order == null) {
          await _dbService.addOrder(order);
          if (mounted) {
            _showSnackbar('Order created successfully!');
          }
        } else {
          await _dbService.updateOrder(order);
          if (mounted) _showSnackbar('Order updated successfully!');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) _showSnackbar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.order == null ? 'New Order' : 'Edit Order',
      showAppBar: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Order Details', 
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      // Item Type Input
                      TextFormField(
                        controller: _itemTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Item Type',
                          hintText: 'e.g., Shirt, Pant',
                          prefixIcon: Icon(Icons.checkroom),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter an item type'
                            : null,
                      ),
                      const SizedBox(height: 16),
            
                      // Description Input
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
            
                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
            
                      // Date Picker Row
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
            
                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                      const SizedBox(height: 16),

                      // New Lab 7 Controls
                      // Checkbox for Rush Order
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Rush Order"),
                        subtitle: const Text("Mark this as high priority"),
                        value: _isRush,
                        onChanged: (val) => setState(() => _isRush = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading, 
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      
                      const SizedBox(height: 16),

                      // Radio Buttons for Payment Method
                      Text("Payment Method", style: Theme.of(context).textTheme.titleSmall),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Cash"),
                              value: 'cash',
                              groupValue: _paymentMethod,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Online"),
                              value: 'online',
                              groupValue: _paymentMethod,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
            
                      // Action Button
                      ElevatedButton(
                        onPressed: _saveOrder,
                        child: Text(
                          widget.order == null ? 'Create Order' : 'Update Order',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
