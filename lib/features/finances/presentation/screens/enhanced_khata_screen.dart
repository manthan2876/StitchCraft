import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class EnhancedKhataScreen extends StatefulWidget {
  const EnhancedKhataScreen({super.key});

  @override
  State<EnhancedKhataScreen> createState() => _EnhancedKhataScreenState();
}

class _EnhancedKhataScreenState extends State<EnhancedKhataScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata (Ledger)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Order>>(
        stream: _dbService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];
          final today = DateTime.now();

          // Calculate "Big Three" metrics
          final galla = _calculateGalla(orders, today);
          final udhaar = _calculateUdhaar(orders);
          final ordersDueTomorrow = _calculateOrdersDueTomorrow(orders, today);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big Three Metrics
                _buildBigThreeMetrics(context, galla, udhaar, ordersDueTomorrow),
                
                const SizedBox(height: 24),
                
                // Outstanding Customers List
                _buildOutstandingList(context, orders),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBigThreeMetrics(
    BuildContext context,
    double galla,
    double udhaar,
    int ordersDueTomorrow,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        
        // Galla (Cash Box)
        _buildMetricCard(
          context,
          icon: Icons.account_balance_wallet,
          iconColor: Colors.green,
          label: 'Galla (Cash Box)',
          value: '₹${galla.toStringAsFixed(0)}',
          subtitle: 'Cash collected today',
        ),
        
        const SizedBox(height: 12),
        
        // Udhaar (Credit)
        _buildMetricCard(
          context,
          icon: Icons.credit_card,
          iconColor: Colors.orange,
          label: 'Udhaar (Credit)',
          value: '₹${udhaar.toStringAsFixed(0)}',
          subtitle: 'Total pending payments',
        ),
        
        const SizedBox(height: 12),
        
        // Orders Due Tomorrow
        _buildMetricCard(
          context,
          icon: Icons.event,
          iconColor: Colors.blue,
          label: 'Orders Due Tomorrow',
          value: ordersDueTomorrow.toString(),
          subtitle: 'Orders to deliver',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingList(BuildContext context, List<Order> orders) {
    // Get customers with outstanding balances
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

    final sortedCustomers = customerBalances.values.toList()
      ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    if (sortedCustomers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No outstanding payments! 🎉',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outstanding Payments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        
        ...sortedCustomers.map((customer) => _buildCustomerCard(context, customer)),
      ],
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerBalance customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: customer.daysOverdue > 7
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${customer.totalDue.toStringAsFixed(0)} pending',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${customer.daysOverdue} days overdue',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          
          // WhatsApp Reminder Button (placeholder)
          IconButton(
            icon: const Icon(Icons.message, color: Colors.green),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('WhatsApp reminder for ${customer.customerName}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Send WhatsApp Reminder',
          ),
        ],
      ),
    );
  }

  double _calculateGalla(List<Order> orders, DateTime today) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return orders
        .where((o) =>
            o.orderDate.isAfter(todayStart) &&
            o.orderDate.isBefore(todayEnd) &&
            o.status != 'Cancelled')
        .fold(0.0, (sum, o) => sum + o.advanceAmount);
  }

  double _calculateUdhaar(List<Order> orders) {
    return orders
        .where((o) => o.status != 'Cancelled' && o.status != 'Delivered')
        .fold(0.0, (sum, o) => sum + o.balanceDue);
  }

  int _calculateOrdersDueTomorrow(List<Order> orders, DateTime today) {
    final tomorrow = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
    final tomorrowEnd = tomorrow.add(const Duration(days: 1));
    
    return orders
        .where((o) =>
            o.dueDate != null &&
            o.dueDate!.isAfter(tomorrow) &&
            o.dueDate!.isBefore(tomorrowEnd) &&
            o.status != 'Delivered' &&
            o.status != 'Cancelled')
        .length;
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
