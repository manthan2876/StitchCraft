import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';
import 'package:stitchcraft/core/services/theme_service.dart';
import 'package:stitchcraft/features/profile/screens/sync_status_screen.dart';

class SettingsTab extends StatelessWidget {
  final VoidCallback onDownloadData;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  const SettingsTab({
    super.key,
    required this.onDownloadData,
    required this.onDeleteAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.themeNotifier,
      builder: (context, currentTheme, child) {
        final bool isDark = currentTheme == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cloud Sync & Offline Status Tile
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppTheme.brandPurple),
              title: Text(context.loc.sync_offline_status, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: const Text('Review pending local items & force sync', style: TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkGrey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
                );
              },
            ),
            const Divider(color: Colors.white10),

            // Language Settings Tile
            ListTile(
              leading: Icon(Icons.language, color: theme.colorScheme.onSurface),
              title: Text(context.loc.language_settings, style: TextStyle(color: theme.colorScheme.onSurface)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkGrey),
              onTap: () => Navigator.pushNamed(context, '/language'),
            ),
            const Divider(color: Colors.white10),

            // Theme Toggle Tile (Light / Dark Mode switcher)
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                isDark ? 'Theme Mode: Dark' : 'Theme Mode: Light',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              value: isDark,
              activeThumbColor: AppTheme.brandPurple,
              onChanged: (bool val) {
                themeService.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            const Divider(color: Colors.white10),

            // GDPR Download Tile
            ListTile(
              leading: Icon(Icons.cloud_download_outlined, color: theme.colorScheme.onSurface),
              title: Text(context.loc.download_gdpr, style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: onDownloadData,
            ),
            const Divider(color: Colors.white10),

            // Delete Account Request Tile
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.alertRed),
              title: Text(context.loc.delete_account, style: const TextStyle(color: AppTheme.alertRed)),
              onTap: onDeleteAccount,
            ),
            const Divider(color: Colors.white10),

            // Logout Tile
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppTheme.alertRed.withValues(alpha: 0.08),
              leading: const Icon(Icons.logout_rounded, color: AppTheme.alertRed),
              title: Text(
                context.loc.logout,
                style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.alertRed),
              onTap: onLogout,
            ),
          ],
        );
      },
    );
  }
}
