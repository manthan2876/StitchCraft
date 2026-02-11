import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';


import 'package:stitchcraft/core/widgets/dashboard_action_card.dart';

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
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 20, 
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text("Total Stock Value", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                       const SizedBox(height: 8),
                       const Text("₹ 45,200", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scanner feature coming soon')),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text("Scan Item"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15), 
                        borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory, color: Colors.white, size: 36),
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
