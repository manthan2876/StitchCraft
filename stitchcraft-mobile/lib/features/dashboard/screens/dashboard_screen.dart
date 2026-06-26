import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';
import 'package:stitchcraft/features/dashboard/widgets/drawer_menu.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_done, color: AppTheme.emerald),
            onPressed: () {}, // Sync status
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardItem(
                  context,
                  'New Order',
                  'નવો ઓર્ડર',
                  Icons.content_cut, // Scissors for Cutting
                  AppTheme.deepBronze.withValues(alpha: 0.1),
                  () => Navigator.pushNamed(context, '/create_order_step1'),
                ),
                _buildDashboardItem(
                  context,
                  'Measurements',
                  'માપ',
                  Icons.straighten, // Tape
                  AppTheme.bronzeTint.withValues(alpha: 0.2),
                  () {},
                ),
                _buildDashboardItem(
                  context,
                  'Customers',
                  'ગ્રાહકો',
                  Icons.people_outline,
                  AppTheme.trustGreen.withValues(alpha: 0.1),
                  () {},
                ),
                _buildDashboardItem(
                  context,
                  'Pending',
                  'બાકી ઓર્ડર',
                  Icons.pending_actions,
                  AppTheme.safetyOrange.withValues(alpha: 0.1),
                  () => Navigator.pushNamed(context, '/orders_pending'),
                ),
                _buildDashboardItem(
                  context,
                  'Repairs',
                  'સમારકામ',
                  Icons.build_circle_outlined,
                  AppTheme.alertRed.withValues(alpha: 0.1),
                  () => Navigator.pushNamed(context, '/repairs'),
                ),
                _buildDashboardItem(
                  context,
                  'Khata',
                  'ખાતાવહી',
                  Icons.menu_book, // Ledger book
                  AppTheme.deepBronze.withValues(alpha: 0.1),
                  () {},
                ),
                _buildDashboardItem(
                  context,
                  'Lab 9 - API',
                  'ડિજિટલ લેજર', // Digital Ledger
                  Icons.cloud_sync, // Sync icon
                  AppTheme.trustGreen.withValues(alpha: 0.2),
                  () => Navigator.pushNamed(context, '/posts'),
                ),
                _buildDashboardItem(
                  context,
                  'Lab 10 - Alerts',
                  'નોટિફિકેશન', // Notifications
                  Icons.notifications_active,
                  AppTheme.brickRed.withValues(alpha: 0.1),
                  () => Navigator.pushNamed(context, '/notifications_lab'),
                ),
                _buildDashboardItem(
                  context,
                  'Lab 11 - Advanced',
                  'એડવાન્સ ફીચર્સ', // Advanced Features
                  Icons.auto_awesome,
                  AppTheme.emerald.withValues(alpha: 0.1),
                  () => Navigator.pushNamed(context, '/lab11_advanced'),
                ),
              ],
            ),
          ),
          // Sticky Footer
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To Deliver: 0',
                  style: AppTheme.masterjiTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.brickRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cash: ₹0',
                  style: AppTheme.masterjiTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.emerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return NeoCard(
      onTap: onTap,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.3)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: AppTheme.navyBlue),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.masterjiTheme.textTheme.titleMedium,
            ),
            Text(
              subtitle,
              style: AppTheme.masterjiTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
