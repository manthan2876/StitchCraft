import 'package:flutter/material.dart';
import 'package:stitchcraft/core/models/order_model.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class KhataLedgerScreen extends StatefulWidget {
  const KhataLedgerScreen({super.key});

  @override
  State<KhataLedgerScreen> createState() => _KhataLedgerScreenState();
}

class _KhataLedgerScreenState extends State<KhataLedgerScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _sortBy = 'amount'; // amount, days, name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata (Ledger)'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'amount',
                child: Text('Sort by Amount'),
              ),
              const PopupMenuItem(
                value: 'days',
                child: Text('Sort by Days Overdue'),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _dbService.getOrders(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderSnapshot.hasError) {
            return Center(child: Text('Error: ${orderSnapshot.error}'));
          }

          final orders = orderSnapshot.data ?? [];
          
          // Group orders by customer with outstanding balance
          final Map<String, CustomerLedger> ledgerMap = {};
          
          for (var order in orders) {
            if (order.status != 'Cancelled' && order.balanceDue > 0) {
              if (!ledgerMap.containsKey(order.customerId)) {
                ledgerMap[order.customerId] = CustomerLedger(
                  customerId: order.customerId,
                  customerName: order.customerName,
                  totalDue: 0,
                  orders: [],
                );
              }
              ledgerMap[order.customerId]!.totalDue += order.balanceDue;
              ledgerMap[order.customerId]!.orders.add(order);
            }
          }

          var ledgerList = ledgerMap.values.toList();

          // Sort based on selection
          switch (_sortBy) {
            case 'amount':
              ledgerList.sort((a, b) => b.totalDue.compareTo(a.totalDue));
              break;
            case 'days':
              ledgerList.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
              break;
            case 'name':
              ledgerList.sort((a, b) => a.customerName.compareTo(b.customerName));
              break;
          }

          if (ledgerList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No outstanding balances!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All customers have cleared their dues',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate totals
          double totalUdhaar = ledgerList.fold(0, (sum, item) => sum + item.totalDue);

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Udhaar (Credit)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalUdhaar.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ledgerList.length} Clients',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ledger List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ledgerList.length,
                  itemBuilder: (context, index) {
                    return _buildLedgerCard(ledgerList[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLedgerCard(CustomerLedger ledger) {
    final daysOverdue = ledger.daysOverdue;
    final isOverdue = daysOverdue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOverdue
                ? AppTheme.error.withValues(alpha: 0.1)
                : AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person,
            color: isOverdue ? AppTheme.error : AppTheme.warning,
          ),
        ),
        title: Text(
          ledger.customerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '₹${ledger.totalDue.toStringAsFixed(0)} due',
              style: TextStyle(
                color: isOverdue ? AppTheme.error : AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$daysOverdue days overdue',
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.message, color: AppTheme.success),
          onPressed: () => _sendReminder(ledger),
          tooltip: 'Send WhatsApp Reminder',
        ),
        children: ledger.orders.map((order) {
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.receipt,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            title: Text(
              order.description,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              'Due: ${order.dueDate != null ? DateFormat('dd MMM yyyy').format(order.dueDate!) : 'N/A'}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Text(
              '₹${order.balanceDue.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _sendReminder(CustomerLedger ledger) async {
    // CustomerLedger doesn't have phone number, show info message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number not available in ledger. Please add customer phone in their profile.'),
          backgroundColor: AppTheme.warning,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class CustomerLedger {
  final String customerId;
  final String customerName;
  double totalDue;
  final List<Order> orders;

  CustomerLedger({
    required this.customerId,
    required this.customerName,
    required this.totalDue,
    required this.orders,
  });

  int get daysOverdue {
    if (orders.isEmpty) return 0;
    
    final now = DateTime.now();
    int maxDays = 0;
    
    for (var order in orders) {
      if (order.dueDate != null && order.dueDate!.isBefore(now)) {
        final days = now.difference(order.dueDate!).inDays;
        if (days > maxDays) maxDays = days;
      }
    }
    
    return maxDays;
  }
}
