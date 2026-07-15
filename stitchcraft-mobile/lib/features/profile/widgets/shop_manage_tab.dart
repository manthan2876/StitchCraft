import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class ShopManageTab extends StatelessWidget {
  const ShopManageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> items = [
      {
        'title': 'Karigars (Staff)',
        'subtitle': 'Manage tailors, specialties & status',
        'icon': Icons.engineering_outlined,
        'route': '/karigars',
      },
      {
        'title': 'Sewing Machines',
        'subtitle': 'Manage registry & repair status',
        'icon': Icons.settings_suggest_outlined,
        'route': '/machines',
      },
      {
        'title': 'Inventory & Stock',
        'subtitle': 'Track lining, threads & inventory',
        'icon': Icons.inventory_2_outlined,
        'route': '/inventory',
      },
      {
        'title': 'Customers Directory',
        'subtitle': 'View customer profiles & measurements',
        'icon': Icons.people_outline,
        'route': '/customers',
      },
      {
        'title': 'Fast Lane Repairs',
        'subtitle': 'Quick stitch, hemming & zippers',
        'icon': Icons.build_outlined,
        'route': '/repairs',
      },
      {
        'title': 'Invoices & Bills',
        'subtitle': 'Generate statements & view balance',
        'icon': Icons.receipt_outlined,
        'route': '/invoices',
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NeoCard(
          onTap: () => Navigator.pushNamed(context, item['route']),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'],
                  size: 24,
                  color: AppTheme.brandPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'],
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  item['subtitle'],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppTheme.darkGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
