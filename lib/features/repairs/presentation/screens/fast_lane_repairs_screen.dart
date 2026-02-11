import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/models/repair_job_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class FastLaneRepairsScreen extends StatefulWidget {
  const FastLaneRepairsScreen({super.key});

  @override
  State<FastLaneRepairsScreen> createState() => _FastLaneRepairsScreenState();
}

class _FastLaneRepairsScreenState extends State<FastLaneRepairsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final List<RepairCartItem> _cart = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Quick service presets
  final List<QuickService> _quickServices = [
    QuickService(
      id: 'ZIPPER',
      icon: Icons.vertical_align_center,
      label: 'Chain Badlai',
      labelHindi: 'चेन बदलाई',
      price: 50,
      color: const Color(0xFF6366F1),
    ),
    QuickService(
      id: 'HEM',
      icon: Icons.straighten,
      label: 'Turpai',
      labelHindi: 'तुरपाई',
      price: 30,
      color: const Color(0xFF10B981),
    ),
    QuickService(
      id: 'PICO',
      icon: Icons.checkroom,
      label: 'Fall-Pico',
      labelHindi: 'फॉल-पिको',
      price: 100,
      color: const Color(0xFFEC4899),
    ),
    QuickService(
      id: 'FITTING',
      icon: Icons.design_services,
      label: 'Fitting',
      labelHindi: 'फिटिंग',
      price: 200,
      color: const Color(0xFFF59E0B),
    ),
    QuickService(
      id: 'PATCH',
      icon: Icons.handyman,
      label: 'Patch Work',
      labelHindi: 'पैच वर्क',
      price: 80,
      color: const Color(0xFF8B5CF6),
    ),
    QuickService(
      id: 'BUTTON',
      icon: Icons.circle_outlined,
      label: 'Button Fix',
      labelHindi: 'बटन लगाना',
      price: 20,
      color: const Color(0xFF06B6D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Lane Repairs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Customer Info Section (Quick Entry)
          _buildQuickCustomerInfo(),
          
          // Quick Service Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _quickServices.length,
              itemBuilder: (context, index) {
                return _buildServiceCard(_quickServices[index]);
              },
            ),
          ),
          
          // Cart Summary
          if (_cart.isNotEmpty) _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildQuickCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(QuickService service) {
    final isInCart = _cart.any((item) => item.serviceId == service.id);
    final cartItem = isInCart ? _cart.firstWhere((item) => item.serviceId == service.id) : null;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isInCart ? 8 : 4,
      shadowColor: service.color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _addToCart(service);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                service.color.withValues(alpha: isInCart ? 0.2 : 0.1),
                service.color.withValues(alpha: 0.05),
              ],
            ),
            border: isInCart
                ? Border.all(color: service.color, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  size: 32,
                  color: service.color,
                ),
              ),
              const SizedBox(height: 8),
              
              // Label
              Text(
                service.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              Text(
                service.labelHindi,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              
              // Price
              Text(
                '₹${service.price}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: service.color,
                    ),
              ),
              
              // Quantity badge if in cart
              if (isInCart && cartItem != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: service.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'x${cartItem.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    final total = _cart.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_cart.length} item(s)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _checkout,
              icon: const Icon(Icons.check),
              label: const Text('Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(QuickService service) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.serviceId == service.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(RepairCartItem(
          serviceId: service.id,
          serviceName: service.label,
          price: service.price.toDouble(),
          quantity: 1,
        ));
      }
    });
  }

  Future<void> _checkout() async {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create repair jobs for each cart item
    for (var item in _cart) {
      final repairJob = RepairJob(
        id: '',
        customerId: '',
        customerName: _customerNameController.text,
        customerPhone: _phoneController.text,
        serviceType: item.serviceId,
        complexity: 'MEDIUM',
        price: item.price * item.quantity,
        status: 'pending',
        notes: 'Fast Lane - ${item.serviceName} x${item.quantity}',
        createdDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        completedDate: null,
        syncStatus: 1,
        updatedAt: DateTime.now(),
      );
      
      await _dbService.addRepairJob(repairJob);
    }

    // Show success feedback
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Repair jobs created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear cart and customer info
      setState(() {
        _cart.clear();
        _customerNameController.clear();
        _phoneController.clear();
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class QuickService {
  final String id;
  final IconData icon;
  final String label;
  final String labelHindi;
  final int price;
  final Color color;

  QuickService({
    required this.id,
    required this.icon,
    required this.label,
    required this.labelHindi,
    required this.price,
    required this.color,
  });
}

class RepairCartItem {
  final String serviceId;
  final String serviceName;
  final double price;
  int quantity;

  RepairCartItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.quantity,
  });
}
