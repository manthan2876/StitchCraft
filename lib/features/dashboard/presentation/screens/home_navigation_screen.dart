import 'package:flutter/material.dart';
import 'package:stitchcraft/features/dashboard/presentation/screens/admin_dashboard_screen.dart';

import 'package:stitchcraft/core/services/auth_service.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;
  String _userRole = 'staff'; // Default to restricted
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> _screens = [
      AdminDashboardScreen(userRole: _userRole), // Pass role
      const Placeholder(),     // Gallery Placeholder
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _userRole == 'admin' ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/order_wizard');
        },
        child: const Icon(Icons.add),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
