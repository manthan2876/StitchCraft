import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/models/customer_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/widgets/garment_selector_grid.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';
import 'package:stitchcraft/features/orders/presentation/widgets/style_grid_selector.dart';

class OrderWizardScreen extends StatefulWidget {
  final Order? existingOrder;
  const OrderWizardScreen({super.key, this.existingOrder});

  @override
  State<OrderWizardScreen> createState() => _OrderWizardScreenState();
}

class _OrderWizardScreenState extends State<OrderWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Data State
  Customer? _selectedCustomer;
  String? _garmentType;
  int _quantity = 1;
  late DateTime _deliveryDate;
  bool _hasAstar = false;
  String? _collarStyle = 'Regular';
  String? _cuffStyle = 'Single';
  String? _pocketStyle = 'Regular';
  String? _fabricPhotoPath;
  
  // Service
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.existingOrder != null) {
      _garmentType = widget.existingOrder!.itemTypes.isNotEmpty 
          ? widget.existingOrder!.itemTypes.first 
          : 'Shirt';
      _quantity = 1; // Order model doesn't have quantity per item clearly in flat structure, default to 1
      _deliveryDate = widget.existingOrder!.dueDate ?? DateTime.now().add(const Duration(days: 7));
      _selectedCustomer = Customer(
        id: widget.existingOrder!.customerId,
        name: widget.existingOrder!.customerName,
        phone: '', 
        email: '',
        updatedAt: DateTime.now(),
      );
    } else {
      _garmentType = 'Shirt';
      _deliveryDate = DateTime.now().add(const Duration(days: 7));
    }
  }

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Form(
            key: _formKey,
            child: Stepper(
              type: isNarrow ? StepperType.vertical : StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0 && _selectedCustomer == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
                   return;
                }
                if (_currentStep == 3 && _fabricPhotoPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fabric Photo is MANDATORY')));
                  return;
                }
                if (_currentStep < 5) {
                  setState(() => _currentStep += 1);
                } else {
                   // Finish - Create Order or Save
                   _saveOrder();
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
                       Expanded(
                         child: NeoButton(
                           onPressed: details.onStepContinue, 
                           color: NeoColors.primary,
                           child: Center(
                             child: Text(
                               _currentStep == 5 ? 'CREATE JOB CARD' : 'CONTINUE',
                               textAlign: TextAlign.center,
                               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                           ),
                         ),
                       ),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.person_search, color: AppTheme.primaryColor),
                            SizedBox(width: 12),
                            Text('Tap to Select Client', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      margin: EdgeInsets.zero,
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
            Step(
              title: const Text('Style'),
              content: Column(
                children: [
                  // Astar Toggle
                  NeoCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Astar (Lining) Needed?", style: TextStyle(fontWeight: FontWeight.bold)),
                        NeoToggle(
                          value: _hasAstar,
                          onChanged: (val) => setState(() => _hasAstar = val),
                          label: _hasAstar ? 'YES' : 'NO',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Collar Style
                  StyleGridSelector(
                    title: "Collar Style",
                    options: const ['Regular', 'Chinese', 'Round'],
                    selectedOption: _collarStyle,
                    onSelected: (val) => setState(() => _collarStyle = val),
                  ),
                  const SizedBox(height: 24),
                  // Pocket Style
                  StyleGridSelector(
                    title: "Pocket",
                    options: const ['Regular', 'Double', 'None'],
                    selectedOption: _pocketStyle,
                    onSelected: (val) => setState(() => _pocketStyle = val),
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
            Step(
              title: const Text('Fabric'),
              content: Column(
                children: [
                  const Text("Capture Digital Twin (Fabric)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _fabricPhotoPath = 'mock_path_to_fabric.jpg');
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _fabricPhotoPath != null ? Colors.transparent : Colors.grey.shade100,
                        image: _fabricPhotoPath != null ? const DecorationImage(
                          image: AssetImage('assets/images/fabric_placeholder.jpg'), // Mock
                          fit: BoxFit.cover,
                        ) : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _fabricPhotoPath != null ? NeoColors.success : Colors.grey.shade300,
                          width: 3,
                        ),
                      ),
                      child: _fabricPhotoPath == null ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("TAP TO CAPTURE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ) : Stack(
                        children: [
                          Positioned(
                            top: 10,
                            right: 10,
                            child: CircleAvatar(
                              backgroundColor: NeoColors.success,
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Photo is required for Digital Twin record", style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),
              isActive: _currentStep >= 4,
            ),
            Step(
              title: const Text('Other'),
              content: Column(
                children: [
                  const Text("Audio Instructions", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  NeoButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                    },
                    height: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.settings_voice, size: 48, color: NeoColors.primary),
                        SizedBox(height: 8),
                        Text("Hold Tape-Recorder to Record", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 5,
            ),
          ],
        ),
      );
    },
  ),
);
}

  void _saveOrder() async {
    // Logic to save order with style attributes and optional fabric
    HapticFeedback.mediumImpact();

    final order = Order(
      id: widget.existingOrder?.id ?? '',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      orderDate: DateTime.now(),
      dueDate: _deliveryDate,
      status: 'Pending',
      totalAmount: 500.0, // Base price or calculated
      updatedAt: DateTime.now(),
      description: '$_garmentType with $_collarStyle collar',
      itemTypes: [_garmentType!],
      measurements: <String, dynamic>{},
      styleAttributes: {
        'collar': _collarStyle!,
        'cuff': _cuffStyle!,
        'pocket': _pocketStyle!,
        'astar': _hasAstar.toString(),
      },
      isRush: false,
    );

    if (widget.existingOrder == null) {
      await _dbService.addOrder(order);
    } else {
      await _dbService.updateOrder(order);
    }

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }
}
