import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/repair_job_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class AddRepairJobScreen extends StatefulWidget {
  final String serviceType;
  final RepairJob? existingJob;

  const AddRepairJobScreen({
    super.key,
    required this.serviceType,
    this.existingJob,
  });

  @override
  State<AddRepairJobScreen> createState() => _AddRepairJobScreenState();
}

class _AddRepairJobScreenState extends State<AddRepairJobScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _customerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  
  String _complexity = 'MEDIUM';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.existingJob?.customerName ?? '');
    _phoneController = TextEditingController(text: widget.existingJob?.customerPhone ?? '');
    _priceController = TextEditingController(text: widget.existingJob?.price.toString() ?? _getDefaultPrice());
    _notesController = TextEditingController(text: widget.existingJob?.notes ?? '');
    _complexity = widget.existingJob?.complexity ?? 'MEDIUM';
    _dueDate = widget.existingJob?.dueDate;
  }

  String _getDefaultPrice() {
    switch (widget.serviceType) {
      case 'ZIPPER':
        return '100';
      case 'HEM':
        return '50';
      case 'PICO':
        return '150';
      case 'FITTING':
        return '200';
      case 'PATCH':
        return '80';
      default:
        return '100';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingJob == null ? 'Add Repair Job' : 'Edit Repair Job'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _complexity,
              decoration: const InputDecoration(
                labelText: 'Complexity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low (1x)')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (1.2x)')),
                DropdownMenuItem(value: 'HIGH', child: Text('High (1.5x)')),
              ],
              onChanged: (value) {
                setState(() {
                  _complexity = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(_dueDate == null ? 'Not set' : _dueDate!.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDueDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveRepairJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.existingJob == null ? 'Create Repair Job' : 'Update Repair Job',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveRepairJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repairJob = RepairJob(
      id: widget.existingJob?.id ?? '',
      customerId: widget.existingJob?.customerId ?? '',
      customerName: _customerNameController.text,
      customerPhone: _phoneController.text,
      serviceType: widget.serviceType,
      complexity: _complexity,
      price: double.parse(_priceController.text),
      status: widget.existingJob?.status ?? 'pending',
      notes: _notesController.text,
      createdDate: widget.existingJob?.createdDate ?? DateTime.now(),
      dueDate: _dueDate,
      completedDate: widget.existingJob?.completedDate,
      syncStatus: 1,
      updatedAt: DateTime.now(),
    );

    if (widget.existingJob == null) {
      await _dbService.addRepairJob(repairJob);
    } else {
      await _dbService.updateRepairJob(repairJob);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
