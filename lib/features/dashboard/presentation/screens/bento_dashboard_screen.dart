import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/widgets/neo_skeuomorphic_widgets.dart';

/// Masterji Command Center - Bento Grid Dashboard
class BentoDashboardScreen extends StatefulWidget {
  const BentoDashboardScreen({super.key});

  @override
  State<BentoDashboardScreen> createState() => _BentoDashboardScreenState();
}

class _BentoDashboardScreenState extends State<BentoDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isShopOpen = true;
  bool _showGallaExpenses = false;

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
                  return _buildBentoGrid(context, orders);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _authService.getCurrentUserData(),
              builder: (context, snapshot) {
                final shopName = snapshot.data?['shopName'] ?? 'StitchCraft';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: NeoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    NeoToggle(
                      value: _isShopOpen,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        setState(() => _isShopOpen = value);
                      },
                      label: _isShopOpen ? 'Open' : 'Closed',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Connectivity Badge (Traffic Light)
          _buildConnectivityBadge(),
        ],
      ),
    );
  }

  Widget _buildConnectivityBadge() {
    // TODO: Implement actual connectivity check
    final badgeColor = NeoColors.success;
    final bgColor = NeoColors.success.withValues(alpha: 0.1);
    final statusText = 'Synced';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, List<Order> orders) {
    final today = DateTime.now();
    final dueToday = orders.where((o) =>
        o.dueDate != null &&
        _isSameDate(o.dueDate!, today) &&
        o.status != 'Delivered').toList();
    
    final todayCash = _calculateTodayCash(orders, today);
    final todayExpenses = _calculateTodayExpenses(today);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Large New Order FAB + Wide Urgency Module
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Square - New Order FAB
              Expanded(
                flex: 1,
                child: _buildNewOrderFAB(),
              ),
              const SizedBox(width: 16),
              
              // Wide Rectangle - Urgency Module
              Expanded(
                flex: 2,
                child: _buildUrgencyModule(dueToday),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row 2: Galla Card + Fast Lane Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Square - Galla Card
              Expanded(
                child: _buildGallaCard(todayCash, todayExpenses),
              ),
              const SizedBox(width: 16),
              
              // Small Square - Fast Lane Toggle
              Expanded(
                child: _buildFastLaneToggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderFAB() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/order_wizard');
      },
        child: Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.content_cut,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New Order',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'नया ऑर्डर',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildUrgencyModule(List<Order> dueToday) {
    return NeoCard(
      height: 200,
      color: NeoColors.error.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: NeoColors.error, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Due Today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NeoColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dueToday.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Horizontal scrolling ticker
          Expanded(
            child: dueToday.isEmpty
                ? const Center(
                    child: Text(
                      'No orders due today! 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        color: NeoColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dueToday.length,
                    itemBuilder: (context, index) {
                      final order = dueToday[index];
                      return _buildUrgencyCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(Order order) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.error, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Customer Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: NeoColors.primary.withValues(alpha: 0.2),
            child: Text(
              order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NeoColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Customer Name
          Text(
            order.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoColors.textPrimary,
            ),
          ),
          
          // Garment Icon
          Icon(
            _getGarmentIcon(order.itemTypes),
            size: 20,
            color: NeoColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildGallaCard(double cash, double expenses) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showGallaExpenses = !_showGallaExpenses);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: child,
          );
        },
        child: _showGallaExpenses
            ? _buildGallaExpensesSide(expenses)
            : _buildGallaCashSide(cash),
      ),
    );
  }

  Widget _buildGallaCashSide(double cash) {
    return NeoCard(
      key: const ValueKey('cash'),
      height: 180,
      color: NeoColors.success.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: NeoColors.success,
          ),
          const SizedBox(height: 12),
          const Text(
            'Galla',
            style: TextStyle(
              fontSize: 16,
              color: NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${cash.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: NeoColors.success,
            ),
          ),
          const Text(
            'Tap to see expenses',
            style: TextStyle(
              fontSize: 10,
              color: NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallaExpensesSide(double expenses) {
    return NeoCard(
      key: const ValueKey('expenses'),
      height: 180,
      color: NeoColors.error.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.trending_down,
            size: 48,
            color: NeoColors.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'Expenses',
            style: TextStyle(
              fontSize: 16,
              color: NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${expenses.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: NeoColors.error,
            ),
          ),
          const Text(
            'Tap to see cash',
            style: TextStyle(
              fontSize: 10,
              color: NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastLaneToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/repairs');
      },
      child: NeoCard(
        height: 180,
        color: NeoColors.warning.withValues(alpha: 0.1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NeoColors.warning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build,
                  size: 48,
                  color: NeoColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fast Lane',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeoColors.textPrimary,
                ),
              ),
              const Text(
                'Repairs',
                style: TextStyle(
                  fontSize: 14,
                  color: NeoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGarmentIcon(List<String> itemTypes) {
    final types = itemTypes.join(' ').toLowerCase();
    if (types.contains('shirt')) return Icons.checkroom;
    if (types.contains('pant')) return Icons.dry_cleaning;
    if (types.contains('saree')) return Icons.woman;
    if (types.contains('blouse')) return Icons.woman_2;
    return Icons.checkroom;
  }

  bool _isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  double _calculateTodayCash(List<Order> orders, DateTime today) {
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return orders
        .where((o) =>
            o.orderDate.isAfter(todayStart) &&
            o.orderDate.isBefore(todayEnd) &&
            o.status != 'Cancelled')
        .fold(0.0, (sum, o) => sum + o.advanceAmount);
  }

  double _calculateTodayExpenses(DateTime today) {
    // TODO: Implement actual expense tracking
    return 0.0;
  }
}
