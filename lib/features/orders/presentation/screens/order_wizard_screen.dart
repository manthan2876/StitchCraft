import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/models/customer_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:stitchcraft/core/widgets/garment_selector_grid.dart';

class OrderWizardScreen extends StatefulWidget {
  const OrderWizardScreen({super.key});

  @override
  State<OrderWizardScreen> createState() => _OrderWizardScreenState();
}

class _OrderWizardScreenState extends State<OrderWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Data State
  Customer? _selectedCustomer;
  String? _garmentType = 'Shirt';
  int _quantity = 1;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  
  // Service
  final DatabaseService _dbService = DatabaseService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Customer && _selectedCustomer == null) {
      _selectedCustomer = args;
    }
  }

  Future<void> _selectClient() async {
     // Currently we don't have a picker dialog, so we just pick the first one from DB or show a simple dialog
     // For this MVP, let's just pick one or assume user passed it.
     // If no user passed, we show a simple list dialog
     
     if (_selectedCustomer != null) return; // Already selected

     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Select Client'),
         content: SizedBox(
           width: double.maxFinite,
           child: StreamBuilder<List<Customer>>(
             stream: _dbService.getCustomers(),
             builder: (context, snapshot) {
               if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
               return ListView.separated(
                 shrinkWrap: true,
                 itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => const Divider(),
                 itemBuilder: (context, index) {
                   final c = snapshot.data![index];
                   return ListTile(
                     title: Text(c.name),
                     subtitle: Text(c.phone),
                     onTap: () {
                       setState(() => _selectedCustomer = c);
                       Navigator.pop(context);
                     },
                   );
                 },
               );
             },
           ),
         ),
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('New Order')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0 && _selectedCustomer == null) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
               return;
            }
            if (_currentStep < 2) {
              setState(() => _currentStep += 1);
            } else {
               // Finish - Navigate to Fabric/Specs with accumulated data
               final orderData = {
                 'customer': _selectedCustomer,
                 'itemType': _garmentType,
                 'quantity': _quantity,
                 'deliveryDate': _deliveryDate,
               };
               Navigator.pushNamed(context, '/garment_specs', arguments: orderData);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
             return Padding(
               padding: const EdgeInsets.only(top: 24.0),
               child: Row(
                 children: [
                   Expanded(child: ElevatedButton(onPressed: details.onStepContinue, child: Text(_currentStep == 2 ? 'Next: Specs' : 'Continue'))),
                   const SizedBox(width: 16),
                   if (_currentStep > 0)
                     TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                 ],
               ),
             );
          },
          steps: [
            Step(
              title: const Text('Client'),
              content: Column(
                children: [
                   if (_selectedCustomer == null)
                    InkWell(
                      onTap: _selectClient,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.person_search, color: Colors.grey),
                            SizedBox(width: 12),
                            Text('Tap to Select Client', style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppTheme.primaryColor),
                          ),
                          title: Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_selectedCustomer!.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selectedCustomer = null),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Garment'),
              content: Column(
                children: [
                   const Text('Select Garment Type', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   GarmentSelectorGrid(
                     selectedType: _garmentType,
                     onSelected: (val) => setState(() => _garmentType = val),
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     initialValue: _quantity.toString(),
                     decoration: const InputDecoration(labelText: 'Quantity', suffixText: 'pcs'),
                     keyboardType: TextInputType.number,
                     onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
                   ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Dates'),
              content: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _deliveryDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setState(() => _deliveryDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Delivery Date', suffixIcon: Icon(Icons.calendar_today)),
                      child: Text(DateFormat('dd MMM yyyy').format(_deliveryDate)),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
