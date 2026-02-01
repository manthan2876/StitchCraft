import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';

import '../../widgets/dashboard_action_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Inventory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                       Text("Total Stock Value", style: TextStyle(color: Colors.white70)),
                       SizedBox(height: 8),
                       Text("₹ 45,200", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.inventory, color: Colors.white, size: 32),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Categories Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                DashboardActionCard(
                  label: "Fabrics",
                  icon: Icons.texture,
                  color: Colors.indigo,
                  badgeText: "12 Rolls",
                  onTap: () {},
                ),
                DashboardActionCard(
                  label: "Buttons & Zippers",
                  icon: Icons.radio_button_checked,
                  color: Colors.amber,
                  badgeText: "Low Stock",
                  onTap: () {},
                ),
                DashboardActionCard(
                  label: "Threads",
                  icon: Icons.gesture,
                  color: Colors.pink,
                  onTap: () {},
                ),
                DashboardActionCard(
                  label: "Needles & Tools",
                  icon: Icons.construction,
                  color: Colors.blueGrey,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
            // Add Item
        }, 
        child: const Icon(Icons.add),
      ),
    );
  }
}
