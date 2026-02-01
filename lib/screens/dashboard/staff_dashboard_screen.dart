import 'package:flutter/material.dart';
import 'package:stitchcraft/theme/app_theme.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Job Cards'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _JobCard(index: index);
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final int index;
  const _JobCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Cutting', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kurta Pajama (Navy Blue)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Due: Today, 5:00 PM', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
             const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
