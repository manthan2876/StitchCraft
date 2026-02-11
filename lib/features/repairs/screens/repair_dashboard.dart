import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class RepairDashboard extends StatefulWidget {
  const RepairDashboard({super.key});

  @override
  State<RepairDashboard> createState() => _RepairDashboardState();
}

class _RepairDashboardState extends State<RepairDashboard> {
  int _totalCost = 0;
  final Map<String, int> _cart = {};

  final List<Map<String, dynamic>> _repairItems = [
    {'name': 'Zipper Replace', 'price': 50, 'icon': Icons.whatshot}, // Placeholder icon
    {'name': 'Button Stitch', 'price': 10, 'icon': Icons.radio_button_checked},
    {'name': 'Hemming', 'price': 30, 'icon': Icons.architecture},
    {'name': 'Fitting', 'price': 80, 'icon': Icons.accessibility},
    {'name': 'Patch Work', 'price': 40, 'icon': Icons.extension},
    {'name': 'Ironing', 'price': 20, 'icon': Icons.iron},
  ];

  void _addItem(String name, int price) {
    setState(() {
      _totalCost += price;
      _cart[name] = (_cart[name] ?? 0) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Fast Lane Repairs')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _repairItems.length,
              itemBuilder: (context, index) {
                final item = _repairItems[index];
                final count = _cart[item['name']] ?? 0;
                
                return NeoCard(
                  onTap: () => _addItem(item['name'], item['price']),
                  color: count > 0 ? AppTheme.marigold.withValues(alpha: 0.2) : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'], size: 32, color: AppTheme.navyBlue),
                      const SizedBox(height: 8),
                      Text(
                        item['name'],
                        style: AppTheme.masterjiTheme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '₹${item['price']}',
                        style: AppTheme.masterjiTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.emerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (count > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.navyBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count in cart',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Cart Footer
          if (_totalCost > 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Cost', style: TextStyle(color: Colors.grey)),
                      Text(
                        '₹$_totalCost',
                        style: AppTheme.masterjiTheme.textTheme.displayLarge?.copyWith(
                          color: AppTheme.emerald,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Repair Order Created!')),
                      );
                      setState(() {
                        _cart.clear();
                        _totalCost = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('CREATE TICKET'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
