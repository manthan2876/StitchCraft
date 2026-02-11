import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/database_service.dart';
import 'package:stitchcraft/core/models/order_model.dart';

import 'package:stitchcraft/core/widgets/app_drawer.dart';
import 'package:stitchcraft/core/widgets/dashboard_action_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String userRole;
  const AdminDashboardScreen({super.key, this.userRole = 'admin'});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final isAdmin = userRole == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isAdmin ? 'Owner Dashboard' : 'Staff Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: db.getOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          
          // Calculations
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final urgentOrders = orders.where((o) {
             if (o.status == 'Completed' || o.status == 'Delivered') return false;
             if (o.dueDate == null) return false;
             return o.dueDate!.isBefore(today.add(const Duration(days: 1)));
          }).toList();

          final pendingCount = orders.where((o) => o.status == 'Pending').length;
          final inProgressCount = orders.where((o) => o.status == 'In Progress' || o.status == 'in_progress').length;
          final readyCount = orders.where((o) => o.status == 'Completed').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. URGENT NOTICES
                if (urgentOrders.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${urgentOrders.length} Urgent Deliveries",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text("Tap to view details", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                // 2. MAIN ACTIONS GRID
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.1, // Slightly wider for modern look
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                   if (isAdmin)
                    DashboardActionCard(
                      label: "New Order",
                      icon: Icons.add,
                      color: AppTheme.primaryColor,
                      onTap: () => Navigator.pushNamed(context, '/order_wizard'),
                    ),
                    DashboardActionCard(
                      label: "Measurements",
                      icon: Icons.straighten,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.pushNamed(context, '/measurements'),
                    ),
                    DashboardActionCard(
                      label: "Pending Orders",
                      icon: Icons.timer,
                      color: Colors.orange,
                      badgeText: pendingCount > 0 ? "$pendingCount" : null,
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                    DashboardActionCard(
                      label: "In Progress",
                      icon: Icons.cut,
                      color: Colors.blue,
                      badgeText: inProgressCount > 0 ? "$inProgressCount" : null,
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                    DashboardActionCard(
                      label: "Ready",
                      icon: Icons.check,
                      color: Colors.green,
                      badgeText: readyCount > 0 ? "$readyCount" : null,
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                   if (isAdmin)
                    DashboardActionCard(
                      label: "Inventory",
                      icon: Icons.inventory_2,
                      color: Colors.teal,
                      onTap: () => Navigator.pushNamed(context, '/inventory'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 3. SECONDARY UTILITIES
                if (isAdmin) ...[
                  _SectionHeader(title: "Tools", action: "", onTap: () {}),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _UtilityCard(
                          label: "Clients", 
                          icon: Icons.people, 
                          onTap: () => Navigator.pushNamed(context, '/customers')
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UtilityCard(
                          label: "Invoices", 
                          icon: Icons.receipt, 
                          onTap: () => Navigator.pushNamed(context, '/invoices')
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UtilityCard(
                          label: "Profile", 
                          icon: Icons.store, 
                          onTap: () => Navigator.pushNamed(context, '/profile')
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Financial Snapshot for Admin
                  FutureBuilder<Map<String, double>>(
                    future: db.getFinancialSummary(),
                    builder: (context, snap) {
                       final data = snap.data ?? {'gross_profit': 0.0};
                       return Card(
                         color: AppTheme.success,
                         child: Padding(
                           padding: const EdgeInsets.all(20),
                           child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 const Text("Total Gross Profit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                 Text("₹${data['gross_profit']?.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
                              ],
                           ),
                         ),
                       );
                    }
                  )
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UtilityCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _UtilityCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
