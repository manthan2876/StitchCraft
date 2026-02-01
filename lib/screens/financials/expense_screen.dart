import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense Tracking Not Implemented')));
        },
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
             Icon(Icons.attach_money, size: 64, color: Colors.grey),
             SizedBox(height: 16),
             Text('No expenses recorded'),
          ],
        ),
      ),
    );
  }
}
