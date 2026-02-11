import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/models/repair_job_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

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

  final List<QuickService> _quickServices = [
    QuickService(id: 'ZIPPER', icon: Icons.vertical_align_center, label: 'Chain Badlai', labelHindi: 'चेन बदलाई', price: 50, color: const Color(0xFF6366F1)),
    QuickService(id: 'HEM', icon: Icons.straighten, label: 'Turpai', labelHindi: 'तुरपाई', price: 30, color: const Color(0xFF10B981)),
    QuickService(id: 'PICO', icon: Icons.checkroom, label: 'Fall-Pico', labelHindi: 'फॉल-पिको', price: 100, color: const Color(0xFFEC4899)),
    QuickService(id: 'FITTING', icon: Icons.design_services, label: 'Fitting', labelHindi: 'फिटिंग', price: 200, color: const Color(0xFFF59E0B)),
    QuickService(id: 'PATCH', icon: Icons.handyman, label: 'Patch Work', labelHindi: 'पैच वर्क', price: 80, color: const Color(0xFF8B5CF6)),
    QuickService(id: 'BUTTON', icon: Icons.circle_outlined, label: 'Button Fix', labelHindi: 'बटन लगाना', price: 20, color: const Color(0xFF06B6D4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickCustomerInfo(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.0,
                ),
                itemCount: _quickServices.length,
                itemBuilder: (context, index) => _buildServiceCard(_quickServices[index]),
              ),
            ),
            if (_cart.isNotEmpty) _buildCartSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: NeoColors.surfaceColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              NeoButton(
                width: 48,
                height: 48,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: NeoColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "FAST LANE REPAIRS",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const Text("GUEST MODE", style: TextStyle(color: NeoColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildQuickCustomerInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: NeoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(hintText: "Customer Name (Optional)", border: InputBorder.none, icon: Icon(Icons.person, size: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(QuickService service) {
    final isInCart = _cart.any((item) => item.serviceId == service.id);
    final count = isInCart ? _cart.firstWhere((item) => item.serviceId == service.id).quantity : 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _addToCart(service);
      },
      child: NeoCard(
        padding: const EdgeInsets.all(12),
        color: isInCart ? service.color.withValues(alpha: 0.05) : Colors.white,
        borderColor: isInCart ? service.color : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(service.icon, color: service.color, size: 36),
            const SizedBox(height: 8),
            Text(service.label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(service.labelHindi, style: const TextStyle(fontSize: 10, color: NeoColors.textSecondary)),
            const SizedBox(height: 8),
            Text("₹${service.price}", style: TextStyle(fontWeight: FontWeight.bold, color: service.color)),
            if (isInCart)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: service.color, shape: BoxShape.circle),
                child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    final total = _cart.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: NeoColors.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${_cart.length} SERVICES", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NeoColors.textSecondary)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: NeoColors.textPrimary)),
              ),
            ],
          ),
          NeoButton(
            width: 160,
            height: 60,
            color: NeoColors.primary,
            onPressed: _checkout,
            child: const Text("ADD TO GALLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _addToCart(QuickService service) {
    setState(() {
      final idx = _cart.indexWhere((item) => item.serviceId == service.id);
      if (idx >= 0) _cart[idx].quantity++;
      else _cart.add(RepairCartItem(serviceId: service.id, serviceName: service.label, price: service.price.toDouble(), quantity: 1));
    });
  }

  Future<void> _checkout() async {
    HapticFeedback.mediumImpact();

    final name = _customerNameController.text.isEmpty ? "GUEST" : _customerNameController.text;
    
    // Create repair jobs
    for (var item in _cart) {
      final repairJob = RepairJob(
        id: '',
        customerId: 'GUEST_ID',
        customerName: name,
        customerPhone: '',
        serviceType: item.serviceId,
        complexity: 'LOW',
        price: item.price * item.quantity,
        status: 'Delivered', // Fast lane is immediate
        notes: 'Fast Lane Transaction',
        createdDate: DateTime.now(),
        dueDate: DateTime.now(),
        completedDate: DateTime.now(),
        syncStatus: 1,
        updatedAt: DateTime.now(),
      );
      await _dbService.addRepairJob(repairJob);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ADDED TO GALLA. SCREEN RESET."), backgroundColor: NeoColors.success));
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
