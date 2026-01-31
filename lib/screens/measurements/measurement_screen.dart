import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/measurement_model.dart';
import '../../models/order_model.dart' as order_model;
import '../../models/customer_model.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _notesController = TextEditingController();
  final _measurementControllers = <String, TextEditingController>{};

  Customer? _selectedCustomer;
  order_model.Order? _selectedOrder;
  String _selectedItemType = 'shirt';

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
      appBar: AppBar(title: const Text('Measurements'), elevation: 0),
      body: StreamBuilder<List<Measurement>>(
        stream: _dbService.getMeasurements(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final measurements = snapshot.data!;
          if (measurements.isEmpty) {
            return const Center(
              child: Text('No measurements found. Add one to get started!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    '${measurement.itemType.toUpperCase()} Measurement',
                  ),
                  subtitle: Text('Customer ID: ${measurement.customerId}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showForm(context, measurement),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, measurement),
                      ),
                    ],
                  ),
                  onTap: () => _showMeasurementDetails(context, measurement),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        tooltip: 'Add Measurement',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, Measurement? measurement) {
    final isEditing = measurement != null;

    if (isEditing) {
      _selectedCustomer = null;
      _selectedOrder = null; // Note: Could be enhanced to load the actual order
      _selectedItemType = measurement.itemType;
      _notesController.text = measurement.notes;

      // Pre-fill measurement fields
      for (var entry in measurement.measurements.entries) {
        _measurementControllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    } else {
      _selectedCustomer = null;
      _selectedOrder = null;
      _selectedItemType = 'shirt';
      _notesController.clear();
      _measurementControllers.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      isEditing ? 'Edit Measurement' : 'Add New Measurement',
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
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 12),
                    // Item Type Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItemType,
                      decoration: InputDecoration(
                        labelText: 'Item Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _itemTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                              ),
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
                    const SizedBox(height: 16),
                    // Measurement Fields
                    Text(
                      'Measurements (in cm)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ..._buildMeasurementFields(_selectedItemType),
                    const SizedBox(height: 12),
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      minLines: 2,
                      maxLines: 3,
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

                            try {
                              final measurements = <String, double>{};
                              for (var entry
                                  in _measurementControllers.entries) {
                                if (entry.value.text.isNotEmpty) {
                                  measurements[entry.key] = double.parse(
                                    entry.value.text,
                                  );
                                }
                              }

                              if (isEditing) {
                                final updatedMeasurement = measurement.copyWith(
                                  customerId: _selectedCustomer!.id,
                                  orderId: _selectedOrder?.id ?? '',
                                  itemType: _selectedItemType,
                                  measurements: measurements,
                                  notes: _notesController.text,
                                );
                                await _dbService.updateMeasurement(
                                  updatedMeasurement,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Measurement updated successfully',
                                    ),
                                  ),
                                );
                              } else {
                                final newMeasurement = Measurement(
                                  id: '',
                                  customerId: _selectedCustomer!.id,
                                  orderId: _selectedOrder?.id ?? '',
                                  itemType: _selectedItemType,
                                  measurements: measurements,
                                  measurementDate: DateTime.now(),
                                  notes: _notesController.text,
                                );
                                await _dbService.addMeasurement(newMeasurement);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Measurement added successfully',
                                    ),
                                  ),
                                );
                              }
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: Text(isEditing ? 'Update' : 'Save'),
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
      },
    );
  }

  List<Widget> _buildMeasurementFields(String itemType) {
    final fields = _measurementFields[itemType] ?? [];
    return fields.map((field) {
      _measurementControllers.putIfAbsent(field, () => TextEditingController());

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: _measurementControllers[field],
          decoration: InputDecoration(
            labelText: field,
            suffixText: 'cm',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }).toList();
  }

  void _confirmDelete(BuildContext context, Measurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: const Text(
          'Are you sure you want to delete this measurement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbService.deleteMeasurement(measurement.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Measurement deleted successfully'),
                    ),
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

  void _showMeasurementDetails(BuildContext context, Measurement measurement) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Item Type:', measurement.itemType.toUpperCase()),
            _buildDetailRow('Customer ID:', measurement.customerId),
            if (measurement.orderId.isNotEmpty)
              _buildDetailRow('Order ID:', measurement.orderId),
            _buildDetailRow(
              'Date:',
              measurement.measurementDate.toLocal().toString().split(' ')[0],
            ),
            const SizedBox(height: 12),
            Text(
              'Measurements:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...measurement.measurements.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${e.key}: ${e.value.toStringAsFixed(2)} cm'),
              ),
            ),
            if (measurement.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
              Text(measurement.notes),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showForm(context, measurement);
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
