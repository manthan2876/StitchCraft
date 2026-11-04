import 'package:flutter/material.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = [
      (
        'Workshop & Outsourcing',
        [
          ('Workshop & Partner Jobs', Icons.handshake_outlined, '/my_jobs'),
          ('Inventory', Icons.inventory_2_outlined, '/inventory'),
          ('Repairs', Icons.build_outlined, '/repairs'),
        ],
      ),
      (
        'Money & delivery',
        [
          ('Invoices', Icons.receipt_long_outlined, '/invoices'),
          ('Payments', Icons.payments_outlined, '/payments'),
          ('Deliveries', Icons.local_shipping_outlined, '/deliveries'),
        ],
      ),
      (
        'Account',
        [
          (
            context.loc.notifications,
            Icons.notifications_none,
            '/notifications',
          ),
          (context.loc.profile, Icons.person_outline, '/profile'),
          (context.loc.shop_settings, Icons.settings_outlined, '/shop_settings'),
          (context.loc.sync_status_title, Icons.sync, '/sync_status'),
        ],
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: context.loc.settings_and_hub,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            'Everything else for your shop',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(
              section.$1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  for (var i = 0; i < section.$2.length; i++) ...[
                    ListTile(
                      minTileHeight: 56,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.brandPurple.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          section.$2[i].$2,
                          color: AppTheme.brandPurple,
                        ),
                      ),
                      title: Text(section.$2[i].$1),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pushNamed(context, section.$2[i].$3),
                    ),
                    if (i < section.$2.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
