import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class AddIncomeBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddIncome;

  const AddIncomeBottomSheet({
    super.key,
    required this.onAddIncome,
  });

  @override
  State<AddIncomeBottomSheet> createState() => _AddIncomeBottomSheetState();
}

class _AddIncomeBottomSheetState extends State<AddIncomeBottomSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _categories = [
    'Stitching',
    'Alterations',
    'Fabric Sale',
    'Lining / Astar',
    'Finishing',
    'Other',
  ];
  late String _selectedCategory;
  String _paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _submit() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final category = _selectedCategory == 'Other' && _customCategoryController.text.trim().isNotEmpty
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    final desc = _descriptionController.text.trim();
    final descriptionWithMode = desc.isNotEmpty
        ? '$desc • $_paymentMode'
        : 'Payment received via $_paymentMode';

    final now = DateTime.now().millisecondsSinceEpoch;
    final newIncome = {
      'id': const Uuid().v4(),
      'category': 'Income: $category',
      'amount': amt,
      'description': descriptionWithMode,
      'date': now,
      'type': 'income',
      'sync_status': 1,
      'updated_at': now,
    };

    widget.onAddIncome(newIncome);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.trustGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_downward, color: AppTheme.trustGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Record Income',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Income Category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppTheme.trustGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.trustGreen : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            if (_selectedCategory == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Custom Category Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.trustGreen),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _paymentMode == 'Cash',
                  onSelected: (val) => setState(() => _paymentMode = 'Cash'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('UPI / Online'),
                  selected: _paymentMode == 'UPI / Online',
                  onSelected: (val) => setState(() => _paymentMode = 'UPI / Online'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description / Notes (Optional)',
                prefixIcon: Icon(Icons.notes),
                hintText: 'e.g. Walk-in alteration, 2m fabric sale',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.trustGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.check, size: 20),
                label: const Text(
                  'Save Income Entry',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

