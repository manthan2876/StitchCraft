import 'package:flutter/material.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';

class SettingsTab extends StatelessWidget {
  final VoidCallback onDownloadData;
  final VoidCallback onDeleteAccount;

  const SettingsTab({
    super.key,
    required this.onDownloadData,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.language, color: Colors.white),
          title: const Text('Language Settings (ભાષા પસંદગી)'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.darkGrey),
          onTap: () => Navigator.pushNamed(context, '/language'),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: const Icon(Icons.cloud_download, color: Colors.white),
          title: const Text('Download All Data (GDPR)'),
          onTap: onDownloadData,
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppTheme.alertRed),
          title: const Text('Delete Account Request', style: TextStyle(color: AppTheme.alertRed)),
          onTap: onDeleteAccount,
        ),
      ],
    );
  }
}
