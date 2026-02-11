import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/models/measurement_model.dart';
import 'package:stitchcraft/core/models/order_model.dart' as order_model;
import 'package:stitchcraft/core/models/customer_model.dart';

class AddMeasurementListScreen extends StatefulWidget {
  const AddMeasurementListScreen({super.key});

  @override
  State<AddMeasurementListScreen> createState() => _AddMeasurementListScreenState();
}

class _AddMeasurementListScreenState extends State<AddMeasurementListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _measurementControllers = <String, TextEditingController>{};

  Customer? _selectedCustomer;
  order_model.Order? _selectedOrder;
  String _selectedItemType = 'shirt';
  bool _isLoading = false;

  final List<String> _itemTypes = [
    'shirt',
    'pants',
    'dress',
    'jacket',
    'skirt',
    'blouse',
    'coat',
    'custom',
  ];

  final Map<String, List<String>> _measurementFields = {
    'shirt': [
      'Chest',
      'Shoulder',
      'Sleeve Length',
      'Waist',
      'Length',
      'Armhole',
    ],
    'pants': ['Waist', 'Inseam', 'Outseam', 'Thigh', 'Knee', 'Leg Opening'],
    'dress': ['Bust', 'Waist', 'Hip', 'Shoulder', 'Length', 'Armhole'],
    'jacket': [
      'Chest',
      'Shoulder',
      'Sleeve Length',
      'Waist',
      'Length',
      'Armhole',
    ],
    'skirt': ['Waist', 'Hip', 'Length', 'Knee'],
    'blouse': ['Chest', 'Shoulder', 'Sleeve Length', 'Waist', 'Length'],
    'coat': [
      'Chest',
      'Shoulder',
      'Sleeve Length',
      'Waist',
      'Length',
      'Armhole',
    ],
    'custom': ['Measurement 1', 'Measurement 2', 'Measurement 3'],
  };

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Measurement'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple,
                child: Icon(Icons.straighten, size: 50, color: Colors.white),
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
                  return DropdownButtonFormField<Customer>(
                    initialValue: _selectedCustomer,
                    hint: const Text('Select Customer *'),
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
              // Order Selection (Optional)
              if (_selectedCustomer != null)
                StreamBuilder<List<order_model.Order>>(
                  stream: _dbService.getOrdersByCustomerId(
                    _selectedCustomer!.id,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('No orders for this customer');
                    }

                    final orders = snapshot.data!;
                    return DropdownButtonFormField<order_model.Order>(
                      initialValue: _selectedOrder,
                      hint: const Text('Select Order (Optional)'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.shopping_bag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: orders
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                'Order ${o.id.substring(0, 8)} - ${o.description}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedOrder = value);
                      },
                    );
                  },
                ),
              if (_selectedCustomer != null) const SizedBox(height: 16),
              // Item Type Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedItemType,
                decoration: InputDecoration(
                  labelText: 'Item Type *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _itemTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedItemType = value;
                      _measurementControllers.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              // Measurement Fields Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Measurements (in cm)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildMeasurementFields(_selectedItemType),
              const SizedBox(height: 16),
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeasurement,
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
                          'Save Measurement',
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

  List<Widget> _buildMeasurementFields(String itemType) {
    final fields = _measurementFields[itemType] ?? [];
    return fields.map((field) {
      _measurementControllers.putIfAbsent(field, () => TextEditingController());

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: _measurementControllers[field],
          decoration: InputDecoration(
            labelText: field,
            suffixText: 'cm',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }).toList();
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final measurements = <String, double>{};
      for (var entry in _measurementControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          measurements[entry.key] = double.parse(entry.value.text);
        }
      }

      final newMeasurement = Measurement(
        id: '',
        customerId: _selectedCustomer!.id,
        orderId: _selectedOrder?.id ?? '',
        itemType: _selectedItemType,
        measurements: measurements,
        measurementDate: DateTime.now(),
        notes: _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _dbService.addMeasurement(newMeasurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement added successfully!'),
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
