import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class ShopsTab extends StatelessWidget {
  final List<dynamic> shops;
  final String? activeShopId;
  final ValueChanged<String> onSwitchShop;

  const ShopsTab({
    super.key,
    required this.shops,
    required this.activeShopId,
    required this.onSwitchShop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        final bool isActive = shop['_id'] == activeShopId;

        return NeoCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: AppTheme.brandPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop['shopName'] ?? 'Shop',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      shop['address'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGrey),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle, color: AppTheme.trustGreen)
              else
                TextButton(
                  onPressed: () => onSwitchShop(shop['_id']),
                  child: const Text('Switch'),
                ),
            ],
          ),
        );
      },
    );
  }
}
