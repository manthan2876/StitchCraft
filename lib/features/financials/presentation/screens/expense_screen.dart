import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddExpenseDialog() {
    final _categoryController = TextEditingController();
    final _amountController = TextEditingController();
    final _descriptionController = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Rent', 'Electricity', 'Salaries', 'Maintenance', 'Marketing', 'Tools', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => _categoryController.text = val ?? '',
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_categoryController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                await _dbService.addExpense(
                  _categoryController.text,
                  double.parse(_amountController.text),
                  _descriptionController.text,
                  _selectedDate,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Financial Summary Card
          FutureBuilder<Map<String, double>>(
            future: _dbService.getFinancialSummary(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? {'expenses': 0.0};
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Expenses', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##0').format(data['expenses'])}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.trending_down, color: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Expense List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.getExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final expenses = snapshot.data!;
                
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No expenses recorded', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense['id']),
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _dbService.deleteExpense(expense['id']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.category, color: Colors.blueGrey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(expense['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (expense['description'] != null)
                                    Text(expense['description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(expense['date'])),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '- ₹${expense['amount']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
