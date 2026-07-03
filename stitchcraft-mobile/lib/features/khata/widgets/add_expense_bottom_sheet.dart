import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class AddExpenseBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddExpense;

  const AddExpenseBottomSheet({
    super.key,
    required this.onAddExpense,
  });

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.record_new_expense,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _categoryController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: context.loc.expense_category_hint,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: context.loc.amount_rs,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: context.loc.short_description,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final cat = _categoryController.text.trim();
                final amt = double.tryParse(_amountController.text) ?? 0.0;
                final desc = _descriptionController.text.trim();

                if (cat.isNotEmpty && amt > 0) {
                  final newExpense = {
                    'id': const Uuid().v4(),
                    'category': cat,
                    'amount': amt,
                    'description': desc,
                    'date': DateTime.now().millisecondsSinceEpoch,
                    'sync_status': 1,
                    'updated_at': DateTime.now().millisecondsSinceEpoch,
                  };
                  widget.onAddExpense(newExpense);
                  Navigator.pop(context);
                }
              },
              child: Text(context.loc.add_expense),
            ),
          ),
        ],
      ),
    );
  }
}
