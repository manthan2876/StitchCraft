import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/widgets/main_layout.dart';
import 'package:stitchcraft/features/financials/presentation/widgets/financial_summary_widget.dart';
import 'package:stitchcraft/core/widgets/visual_selector_grid.dart';
import 'package:stitchcraft/features/orders/presentation/widgets/fabric_digital_twin.dart';
import 'package:stitchcraft/features/orders/presentation/widgets/status_timeline.dart';

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
  
  // Job Costing controllers
  late TextEditingController _laborCostController;
  late TextEditingController _materialCostController;
  late TextEditingController _overheadCostController;
  
  // Style Attributes
  final Map<String, String> _styleAttributes = {};
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'Pending';
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
    
    _laborCostController = TextEditingController(
      text: widget.order?.laborCost.toString() ?? '0.0',
    );
    _materialCostController = TextEditingController(
      text: widget.order?.materialCost.toString() ?? '0.0',
    );
    _overheadCostController = TextEditingController(
      text: widget.order?.overheadCost.toString() ?? '0.0',
    );
    
    if (widget.order != null) {
      _selectedDate = widget.order!.dueDate ?? DateTime.now();
      _status = widget.order!.status;
      _isRush = widget.order!.isRush;
      _paymentMethod = widget.order!.paymentMethod;
      _styleAttributes.addAll(widget.order!.styleAttributes);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _itemTypeController.dispose();
    _laborCostController.dispose();
    _materialCostController.dispose();
    _overheadCostController.dispose();
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
        totalAmount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        dueDate: _selectedDate,
        status: _status,
        orderDate: widget.order?.orderDate ?? DateTime.now(),
        updatedAt: DateTime.now(),
        measurements: widget.order?.measurements ?? {},
        isRush: _isRush,
        paymentMethod: _paymentMethod,
        laborCost: double.tryParse(_laborCostController.text) ?? 0.0,
        materialCost: double.tryParse(_materialCostController.text) ?? 0.0,
        overheadCost: double.tryParse(_overheadCostController.text) ?? 0.0,
        styleAttributes: Map<String, String>.from(_styleAttributes),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Timeline
              StatusTimeline(
                currentStatus: _status,
                onStatusChanged: (val) => setState(() => _status = val),
              ),
              const SizedBox(height: 24),
              
              if (widget.order != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: FinancialSummaryWidget(order: widget.order!),
                ),
              
              // Fabric Digital Twin
              const FabricDigitalTwin(),
              const SizedBox(height: 24),

              Text('Job Details', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _itemTypeController,
                decoration: const InputDecoration(
                  labelText: 'Item Type',
                  hintText: 'e.g., Shirt, Pant',
                  prefixIcon: Icon(Icons.checkroom),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Instructions',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Visual Selectors
              VisualSelectorGrid(
                title: 'Collar Style',
                options: const [
                  {'id': 'Spread', 'label': 'Spread', 'icon': Icons.expand},
                  {'id': 'Mandarin', 'label': 'Mandarin', 'icon': Icons.crop_portrait},
                  {'id': 'ButtonDown', 'label': 'Button-Down', 'icon': Icons.radio_button_checked},
                ],
                selectedId: _styleAttributes['Collar'] ?? '',
                onSelected: (val) => setState(() => _styleAttributes['Collar'] = val),
              ),
              const SizedBox(height: 24),
              VisualSelectorGrid(
                title: 'Cuff Style',
                options: const [
                  {'id': 'Barrel', 'label': 'Barrel', 'icon': Icons.rectangle_outlined},
                  {'id': 'French', 'label': 'French', 'icon': Icons.flip},
                  {'id': 'Convertible', 'label': 'Convertible', 'icon': Icons.loop},
                ],
                selectedId: _styleAttributes['Cuff'] ?? '',
                onSelected: (val) => setState(() => _styleAttributes['Cuff'] = val),
              ),
              
              const SizedBox(height: 32),
              
              // Financials
               Text(
                'Job Costing', 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Price (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _laborCostController,
                      decoration: const InputDecoration(labelText: 'Labor (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
               children: [
                  Expanded(
                    child: TextFormField(
                      controller: _materialCostController,
                      decoration: const InputDecoration(labelText: 'Material (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _overheadCostController,
                      decoration: const InputDecoration(labelText: 'Overhead(₹)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Due Date & Rush
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('EEE, MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Rush Order (High Priority)"),
                value: _isRush,
                onChanged: (val) => setState(() => _isRush = val ?? false),
                activeColor: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveOrder,
                child: Text(widget.order == null ? 'Create Order' : 'Update Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
