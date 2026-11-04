import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/features/dashboard/screens/dashboard_screen.dart';
import 'package:stitchcraft/features/orders/screens/order_list_screen.dart';
import 'package:stitchcraft/features/khata/screens/khata_screen.dart';
import 'package:stitchcraft/features/orders/screens/customer_list_screen.dart';
import 'package:stitchcraft/features/dashboard/screens/more_hub_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _selectedIndex = 0;
  bool _isCheckingAuth = true;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _verifySession();
    _screens = [
      const DashboardScreen(isTab: true),
      const OrderListScreen(title: 'Orders', statusFilter: 'all', isTab: true),
      const CustomerListScreen(isTab: true),
      const KhataScreen(initialTabIndex: 0, isTab: true),
      const MoreHubScreen(),
    ];
  }

  Future<void> _verifySession() async {
    try {
      final token = await AuthService().getToken();
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? shopId = prefs.getString('shopId');

      if (!isLoggedIn || token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      if (shopId == null || shopId.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/shop_setup');
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isCheckingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.brandPurple),
        ),
      );
    }
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final navBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14.0, 0.0, 14.0, 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildNavItem(0, Icons.grid_view_rounded, context.loc.home, isDark)),
                  Expanded(child: _buildNavItem(1, Icons.shopping_bag_rounded, context.loc.orders, isDark)),
                  Expanded(child: _buildNavItem(2, Icons.people_alt_rounded, context.loc.customers, isDark)),
                  _buildMiddleActionButton(),
                  Expanded(child: _buildNavItem(3, Icons.account_balance_wallet_rounded, context.loc.udhar_ledger, isDark)),
                  Expanded(child: _buildNavItem(4, Icons.more_horiz_rounded, context.loc.more, isDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    final unselectedColor = isDark ? AppTheme.darkGrey : const Color(0xFF667085);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: label,
            button: true,
            selected: isSelected,
            child: Icon(
              icon,
              color: isSelected ? AppTheme.brandPurple : unselectedColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.brandPurple : unselectedColor,
            ),
          ),
        ],
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
        tooltip: 'Create new order',
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.pushNamed(context, '/create_order_customer');
        },
      ),
    );
  }
}
