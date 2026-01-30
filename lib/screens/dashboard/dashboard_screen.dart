import 'package:flutter/material.dart';
import 'package:stitchcraft/services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      // The Hub: Central navigation to all core features
      body: GridView.count(
        padding: EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(context, "Clients", Icons.people, Colors.blue),
          _buildMenuCard(
            context,
            "Measurements",
            Icons.straighten,
            Colors.teal,
          ),
          _buildMenuCard(context, "Orders", Icons.list_alt, Colors.orange),
          _buildMenuCard(
            context,
            "Invoices",
            Icons.receipt_long,
            Colors.purple,
          ),
        ],
      ),
      // Thumb-Friendly FAB for the critical "New Order" flow
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text("New Order"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {},
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
