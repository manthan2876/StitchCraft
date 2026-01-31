import 'package:flutter/material.dart';
import 'package:stitchcraft/services/auth_service.dart';
import 'package:stitchcraft/utils/seeder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
          // Seed data button for development
          if (!_isSeeding)
            IconButton(
              icon: Icon(Icons.cloud_upload),
              onPressed: _seedDatabase,
              tooltip: 'Seed Sample Data',
            ),
          if (_isSeeding)
            Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
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
          _buildMenuCard(
            context,
            "Clients",
            Icons.people,
            Colors.blue,
            route: '/customers',
          ),
          _buildMenuCard(
            context,
            "Measurements",
            Icons.straighten,
            Colors.teal,
            route: '/measurements',
          ),
          _buildMenuCard(
            context,
            "Orders",
            Icons.list_alt,
            Colors.orange,
            route: '/orders',
          ),
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
        onPressed: () => Navigator.pushNamed(context, '/orders'),
        label: const Text("New Order"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);

    try {
      final hasData = await FirebaseSeeder.hasData();

      if (hasData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database already has data. Skipping seeding.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      await FirebaseSeeder.seedAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sample data added to Firestore successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seeding data: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    String? route,
  }) {
    return InkWell(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
