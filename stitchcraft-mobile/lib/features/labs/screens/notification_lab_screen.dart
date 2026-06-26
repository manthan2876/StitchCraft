import 'package:flutter/material.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

class NotificationLabScreen extends StatelessWidget {
  const NotificationLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Lab 10 - Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Permissions'),
            NeoCard(
              child: ListTile(
                leading: const Icon(Icons.security, color: AppTheme.navyBlue),
                title: const Text('Request Permission'),
                subtitle: const Text('Required for Android 13+ and Push'),
                onTap: () => notificationService.requestPermissions(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Local Notifications'),
            NeoCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active, color: AppTheme.emerald),
                    title: const Text('Instant Notification'),
                    subtitle: const Text('Triggers immediately'),
                    onTap: () {
                      final id = DateTime.now().millisecondsSinceEpoch % 100000;
                      notificationService.showInstantNotification(
                        'Instant Alert ($id)',
                        'This confirms notifications are WORKING!',
                        id: id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Instant Alert $id triggered')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timer, color: AppTheme.bronzeTint),
                    title: const Text('Scheduled Notification (5s)'),
                    subtitle: const Text('Wait 5s then trigger. Minimize now!'),
                    onTap: () {
                      final id = DateTime.now().millisecondsSinceEpoch % 100000;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delay started! Minimize the app NOW.')),
                      );
                      // This uses a robust timer that we verified works on your device!
                      Future.delayed(const Duration(seconds: 5), () {
                        notificationService.showInstantNotification(
                          'Scheduled Reminder ($id)',
                          'It is time to deliver the garment!',
                          id: id,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Push Notifications (FCM)'),
            NeoCard(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.cloud_queue, color: AppTheme.navyBlue),
                    title: Text('Test Push Notification'),
                    subtitle: Text('Use Firebase Console to send a message to this device.'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'FCM messages will trigger a local notification when the app is in foreground.',
                      style: AppTheme.masterjiTheme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Note: Test scheduled notifications by minimizing the app.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.masterjiTheme.textTheme.titleMedium?.copyWith(
          color: AppTheme.brickRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
