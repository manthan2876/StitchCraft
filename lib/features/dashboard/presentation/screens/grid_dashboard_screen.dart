import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class GridDashboardScreen extends StatelessWidget {
  const GridDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Language Toggle and Cloud Sync
            _buildHeader(context),
            
            // Grid of Features
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildGridTile(
                      context,
                      icon: Icons.content_cut,
                      label: 'New Order',
                      color: const Color(0xFF6366F1),
                      route: '/order_wizard',
                    ),
                    _buildGridTile(
                      context,
                      icon: Icons.straighten,
                      label: 'Measurements',
                      color: const Color(0xFFF59E0B),
                      route: '/measurements',
                    ),
                    _buildGridTile(
                      context,
                      icon: Icons.inventory_2,
                      label: 'Inventory',
                      color: const Color(0xFF10B981),
                      route: '/inventory',
                    ),
                    _buildGridTile(
                      context,
                      icon: Icons.account_balance_wallet,
                      label: 'Billing/Khata',
                      color: const Color(0xFFEC4899),
                      route: '/khata',
                    ),
                    _buildGridTile(
                      context,
                      icon: Icons.build,
                      label: 'Repairs',
                      color: const Color(0xFF8B5CF6),
                      route: '/repairs',
                    ),
                    _buildGridTile(
                      context,
                      icon: Icons.photo_library,
                      label: 'Portfolio',
                      color: const Color(0xFF06B6D4),
                      route: '/portfolio',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StitchCraft',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
              Text(
                'Your Tailoring Hub',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          
          // Language Toggle and Cloud Sync
          Row(
            children: [
              // Language Toggle (placeholder)
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  // TODO: Implement language selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language selection coming soon')),
                  );
                },
                tooltip: 'Change Language',
              ),
              
              // Cloud Sync Indicator (placeholder)
              IconButton(
                icon: const Icon(Icons.cloud_done, color: Colors.green),
                onPressed: () {
                  // TODO: Implement manual sync
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data synced')),
                  );
                },
                tooltip: 'Cloud Sync Status',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with shadow for depth
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              
              // Label
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
