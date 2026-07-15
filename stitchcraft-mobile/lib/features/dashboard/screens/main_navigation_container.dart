import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/features/dashboard/screens/dashboard_screen.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';
import 'package:stitchcraft/features/khata/screens/khata_screen.dart';
import 'package:stitchcraft/features/shop/screens/shop_hub_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(isTab: true),
      const OrderListScreen(title: 'Orders', statusFilter: 'all', isTab: true),
      const KhataScreen(initialTabIndex: 0, isTab: true),
      const ShopHubScreen(isTab: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6), // Dark Glass base
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
                  _buildNavItem(1, Icons.shopping_bag_rounded, 'Orders'),
                  _buildMiddleActionButton(),
                  _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Ledger'),
                  _buildNavItem(3, Icons.manage_accounts_rounded, 'Shop Hub'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.brandPurple : AppTheme.darkGrey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.brandPurple : AppTheme.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleActionButton() {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: AppTheme.brandPurple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandPurple.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.pushNamed(context, '/create_order_step1');
        },
      ),
    );
  }
}
