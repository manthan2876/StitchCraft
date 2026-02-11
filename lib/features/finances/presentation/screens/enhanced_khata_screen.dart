import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

class EnhancedKhataScreen extends StatefulWidget {
  const EnhancedKhataScreen({super.key});

  @override
  State<EnhancedKhataScreen> createState() => _EnhancedKhataScreenState();
}

class _EnhancedKhataScreenState extends State<EnhancedKhataScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Order>>(
                stream: _dbService.getOrders(),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  final galla = _calculateGalla(orders);
                  final udhaar = _calculateUdhaar(orders);
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryMetrics(galla, udhaar),
                        const SizedBox(height: 24),
                        _buildDebtRadar(orders),
                      ],
                    ),
                  );
                },
              ),
            ),
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
        children: [
          NeoButton(
            width: 48,
            height: 48,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: NeoColors.primary),
          ),
          const SizedBox(width: 16),
          const Text(
            "KHATA RECOVERY",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(double galla, double udhaar) {
    return Row(
      children: [
        Expanded(
          child: NeoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CASH (GALLA)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NeoColors.textSecondary)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("₹${galla.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: NeoColors.success)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PENDING (KHATA)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: NeoColors.textSecondary)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("₹${udhaar.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtRadar(List<Order> orders) {
    final Map<String, CustomerBalance> customerBalances = {};
    for (var order in orders) {
      if (order.balanceDue > 0 && order.status != 'Cancelled') {
        if (!customerBalances.containsKey(order.customerId)) {
          customerBalances[order.customerId] = CustomerBalance(
            customerId: order.customerId,
            customerName: order.customerName,
            totalDue: 0,
            oldestOrderDate: order.orderDate,
          );
        }
        customerBalances[order.customerId]!.totalDue += order.balanceDue;
        if (order.orderDate.isBefore(customerBalances[order.customerId]!.oldestOrderDate)) {
          customerBalances[order.customerId]!.oldestOrderDate = order.orderDate;
        }
      }
    }

    final sortedCustomers = customerBalances.values.toList()..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("DEBT RADAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text("${sortedCustomers.length} Outstandings", style: const TextStyle(fontSize: 12, color: NeoColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        ...sortedCustomers.map((c) => _buildRecoveryCard(c)),
      ],
    );
  }

  Widget _buildRecoveryCard(CustomerBalance customer) {
    final isCritical = customer.daysOverdue >= 30;
    final isWarning = customer.daysOverdue >= 15;
    
    Color severityColor = NeoColors.success;
    if (isCritical) severityColor = Colors.red;
    else if (isWarning) severityColor = Colors.orange;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: isCritical ? [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1 * _pulseController.value),
                blurRadius: 10 * _pulseController.value,
                spreadRadius: 5 * _pulseController.value,
              )
            ] : null,
          ),
          child: NeoCard(
            padding: const EdgeInsets.all(16),
            borderColor: isCritical ? Colors.red.withValues(alpha: 0.5 + 0.5 * _pulseController.value) : null,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${customer.daysOverdue}d",
                      style: TextStyle(fontWeight: FontWeight.bold, color: severityColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("Udhaar: ₹${customer.totalDue.toStringAsFixed(0)}", style: const TextStyle(color: NeoColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                NeoButton(
                  width: 50,
                  height: 50,
                  color: NeoColors.success.withValues(alpha: 0.1),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _sendWhatsApp(customer);
                  },
                  child: const Icon(Icons.message, color: NeoColors.success),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendWhatsApp(CustomerBalance customer) {
    // Simulate WhatsApp Message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ram Ram ${customer.customerName} ji, aapka ₹${customer.totalDue.toStringAsFixed(0)} baki hai..."),
        backgroundColor: NeoColors.success,
      )
    );
  }

  double _calculateGalla(List<Order> orders) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return orders.where((o) => o.orderDate.isAfter(todayStart)).fold(0.0, (sum, o) => sum + o.advanceAmount);
  }

  double _calculateUdhaar(List<Order> orders) {
    return orders.where((o) => o.status != 'Delivered').fold(0.0, (sum, o) => sum + o.balanceDue);
  }
}

class CustomerBalance {
  final String customerId;
  final String customerName;
  double totalDue;
  DateTime oldestOrderDate;

  CustomerBalance({
    required this.customerId,
    required this.customerName,
    required this.totalDue,
    required this.oldestOrderDate,
  });

  int get daysOverdue {
    return DateTime.now().difference(oldestOrderDate).inDays;
  }
}
