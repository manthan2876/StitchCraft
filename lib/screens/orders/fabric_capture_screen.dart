import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../services/database_service.dart';

class FabricCaptureScreen extends StatefulWidget {
  const FabricCaptureScreen({super.key});

  @override
  State<FabricCaptureScreen> createState() => _FabricCaptureScreenState();
}

class _FabricCaptureScreenState extends State<FabricCaptureScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  Future<void> _createOrder(Map<String, dynamic> data) async {
    setState(() => _isSaving = true);
    
    try {
      final customer = data['customer'] as Customer;
      final itemType = data['itemType'] as String;
      final deliveryDate = data['deliveryDate'] as DateTime;
      // final quantity = data['quantity'] as int; // Not in Order model yet, maybe description
      
      final order = Order(
        id: '',
        customerId: customer.id,
        customerName: customer.name,
        orderDate: DateTime.now(),
        dueDate: deliveryDate,
        status: 'Pending',
        totalAmount: 0.0, // Placeholder
        description: 'Custom $itemType order',
        itemTypes: [itemType],
        measurements: {}, // Should pull from customer measurements
        isRush: false,
      );

      await _dbService.addOrder(order);
      
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Created Successfully!')));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Fabric Digital Twin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: (){},
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Capture Fabric Photo', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
             const TextField(
              decoration: InputDecoration(
                labelText: 'Fabric Tag / Brand',
                hintText: 'e.g. Raymond 4045',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Minor defect near corner...',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _createOrder(orderData),
                child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('Create Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
