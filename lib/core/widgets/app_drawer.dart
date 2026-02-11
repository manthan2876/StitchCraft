import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: authService.getCurrentUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              return UserAccountsDrawerHeader(
                accountName: Text(
                  userData?['shopName'] ?? 'StitchCraft',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(userData?['email'] ?? ''),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.store, size: 40, color: AppTheme.primaryColor),
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
               Navigator.pop(context); // Close drawer
               // Already on dashboard usually, or navigate if needed
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/customers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Measurements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/measurements');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/inventory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Repairs & Alterations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/repairs');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile'); // Needs route
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                 Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
