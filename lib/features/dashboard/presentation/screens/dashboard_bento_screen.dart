import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/order_model.dart' as order_model;
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/features/orders/presentation/screens/add_edit_order_screen.dart';
import 'package:stitchcraft/core/widgets/sync_button_widget.dart';

class DashboardBentoScreen extends StatefulWidget {
  const DashboardBentoScreen({super.key});

  @override
  State<DashboardBentoScreen> createState() => _DashboardBentoScreenState();
}

class _DashboardBentoScreenState extends State<DashboardBentoScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              StreamBuilder<List<order_model.Order>>(
                stream: _dbService.getOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final orders = snapshot.data ?? [];
                  final today = DateTime.now();
                  
                  // 1. Urgency Data
                  final deliveryToday = orders.where((o) => 
                    o.dueDate != null && 
                    isSameDate(o.dueDate!, today) && 
                    o.status != 'Delivered'
                  ).toList();
                  
                  // 2. Workflow Data
                  final cuttingCount = orders.where((o) => o.status == 'Cutting').length;
                  final stitchingCount = orders.where((o) => o.status == 'Stitching').length;
                  final readyCount = orders.where((o) => o.status == 'Ready').length;
                  final totalActive = cuttingCount + stitchingCount + readyCount;

                  return Column(
                    children: [
                      _buildUrgencyCard(context, deliveryToday.cast<order_model.Order>().toList()),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildWorkflowCard(context, cuttingCount, stitchingCount, readyCount, totalActive),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildFinancialCard(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Business Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SyncButtonWidget(),
      ],
    );
  }

  Widget _buildUrgencyCard(BuildContext context, List<order_model.Order> urgentOrders) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orders Delivering Today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${urgentOrders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (urgentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No deliveries scheduled for today.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...urgentOrders.take(3).map((order_model.Order order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditOrderScreen(order: order),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            order.itemTypes.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(BuildContext context, int cutting, int stitching, int ready, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text('Workflow', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar('Cutting', cutting, total, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressBar('Stitching', stitching, total, Colors.purple),
          const SizedBox(height: 12),
          _buildProgressBar('Ready', ready, total, Colors.green),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final double progress = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress, // Fixed value for now or calculate
          backgroundColor: color.withValues(alpha: 0.1),
          color: color,
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildFinancialCard() {
    return StreamBuilder<List<order_model.Order>>(
      stream: _dbService.getOrders(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const SizedBox();
        }

        final orders = orderSnapshot.data!;

        // Calculate Galla (Cash collected today)
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        double galla = 0.0;
        for (var order in orders) {
          if (order.orderDate.isAfter(todayStart) &&
              order.orderDate.isBefore(todayEnd) &&
              order.status != 'Cancelled') {
            galla += order.advanceAmount; // Cash collected
          }
        }

        // Calculate Udhaar (Outstanding credit)
        double udhaar = 0.0;
        for (var order in orders) {
          if (order.status != 'Cancelled' && order.status != 'Delivered') {
            udhaar += order.balanceDue; // Remaining balance
          }
        }

        // Orders due tomorrow
        final tomorrow = todayEnd;
        final tomorrowEnd = tomorrow.add(const Duration(days: 1));
        final ordersDueTomorrow = orders.where((order_model.Order o) {
          return o.dueDate != null &&
              o.dueDate!.isAfter(tomorrow) &&
              o.dueDate!.isBefore(tomorrowEnd) &&
              o.status != 'Delivered' &&
              o.status != 'Cancelled';
        }).length;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Galla (Cash Box)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Galla (Cash Box)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${galla.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  
                  // Udhaar and Orders Due
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Udhaar',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${udhaar.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Due Tomorrow',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ordersDueTomorrow Orders',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
      },
    );
  }
}
