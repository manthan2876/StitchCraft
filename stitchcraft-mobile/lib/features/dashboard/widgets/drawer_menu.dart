import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/localization_service.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final _authService = AuthService();
  final _loc = LocalizationService();
  
  String _userName = 'Masterji Tailor';
  String _userRole = 'OWNER';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Masterji Tailor';
      _userRole = prefs.getString('userRole')?.toUpperCase() ?? 'OWNER';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF101828)),
            accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: Text(_userRole, style: const TextStyle(color: AppTheme.brandPurple, fontWeight: FontWeight.bold)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppTheme.brandPurple,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: Text(_loc.t(context, 'home_dashboard')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: Text(_loc.t(context, 'orders')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/orders_pending');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(_loc.t(context, 'customers')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/customers');
                  },
                ),
                
                // Billing & Dispatch Expandable tile
                ExpansionTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(_loc.t(context, 'billing_dispatch')),
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.local_shipping_outlined, size: 20),
                      title: Text(_loc.t(context, 'deliveries')),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/deliveries');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_outlined, size: 20),
                      title: Text(_loc.t(context, 'invoices')),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/invoices');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment_outlined, size: 20),
                      title: Text(_loc.t(context, 'payments')),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/payments');
                      },
                    ),
                  ],
                ),
                
                ListTile(
                  leading: const Icon(Icons.engineering_outlined),
                  title: Text(_loc.t(context, 'karigars')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/karigars');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_suggest_outlined),
                  title: Text(_loc.t(context, 'machines')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/machines');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(_loc.t(context, 'inventory_stock')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(_loc.t(context, 'khata_ledger')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/khata');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(_loc.t(context, 'change_language')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/language');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(_loc.t(context, 'shop_settings')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.alertRed),
            title: Text(
              _loc.t(context, 'logout'),
              style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
