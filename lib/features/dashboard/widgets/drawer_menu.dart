import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.navyBlue),
            accountName: const Text('Masterji Tailors'),
            accountEmail: const Text('+91 9876543210'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.navyBlue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings (Rate Card)'),
            onTap: () {
               // Navigator.pushNamed(context, '/settings');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.brickRed),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.brickRed),
            ),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
