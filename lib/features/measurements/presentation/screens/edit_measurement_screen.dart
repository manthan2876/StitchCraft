import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/models/measurement_model.dart';

class EditMeasurementListScreen extends StatefulWidget {
  final Measurement measurement;

  const EditMeasurementListScreen({super.key, required this.measurement});

  @override
  State<EditMeasurementListScreen> createState() => _EditMeasurementListScreenState();
}

class _EditMeasurementListScreenState extends State<EditMeasurementListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _measurementControllers = <String, TextEditingController>{};

  late String _selectedItemType;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _selectedItemType = widget.measurement.itemType;
    _notesController.text = widget.measurement.notes;

    // Pre-fill measurement fields
    for (var entry in widget.measurement.measurements.entries) {
      _measurementControllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
  }

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
      appBar: AppBar(
        title: const Text('Edit Measurement'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Measurement',
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
                backgroundColor: Colors.purple.shade200,
                child: const Icon(
                  Icons.straighten,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Item Type Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedItemType,
                decoration: InputDecoration(
                  labelText: 'Item Type',
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
                  onPressed: _isLoading ? null : _updateMeasurement,
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
                          'Update Measurement',
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

  Future<void> _updateMeasurement() async {
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

      final updatedMeasurement = widget.measurement.copyWith(
        itemType: _selectedItemType,
        measurements: measurements,
        notes: _notesController.text.trim(),
      );

      await _dbService.updateMeasurement(updatedMeasurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement updated successfully!'),
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
              Navigator.pop(context);
              await _deleteMeasurement();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeasurement() async {
    setState(() => _isLoading = true);

    try {
      await _dbService.deleteMeasurement(widget.measurement.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement deleted successfully!'),
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
