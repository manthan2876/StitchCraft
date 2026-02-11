import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stitchcraft/features/dashboard/presentation/screens/bento_dashboard_screen.dart';
import 'package:stitchcraft/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:stitchcraft/features/orders/presentation/screens/order_list_screen.dart';
import 'package:stitchcraft/features/finances/presentation/screens/enhanced_khata_screen.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/app_drawer.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading if needed, or remove completely. 
    // For now, we removed role check so no need to load it.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> _screens = [
      const BentoDashboardScreen(),
      const CustomerListScreen(),
      const OrderListScreen(),
      const EnhancedKhataScreen(),
    ];

    final List<String> _titles = [
      'Dashboard',
      'Customers',
      'Orders',
      'Finances',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clients',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.attach_money_outlined),
              selectedIcon: Icon(Icons.attach_money),
              label: 'Finances',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/order_wizard');
        },
        tooltip: 'New Order',
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ) : null,
    );
  }
}
