import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchcraft/core/services/notification_service.dart';
import 'package:stitchcraft/core/widgets/custom_app_bar.dart';
import 'package:stitchcraft/core/localization/app_localizations_extension.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _authService = AuthService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        setState(() {
          _notifications = list;
        });

        final prefs = await SharedPreferences.getInstance();
        final alertedIds = prefs.getStringList('alerted_notification_ids') ?? [];
        final List<String> newAlertedIds = List.from(alertedIds);
        bool updated = false;

        for (final n in list) {
          final String id = n['_id'] ?? '';
          final String message = n['message'] ?? '';
          final bool isRead = n['read'] ?? false;
          if (!isRead && !alertedIds.contains(id)) {
            await NotificationService().showInstantNotification("StitchCraft Alert", message, id: id.hashCode);
            newAlertedIds.add(id);
            updated = true;
          }
        }
        if (updated) {
          await prefs.setStringList('alerted_notification_ids', newAlertedIds);
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/notifications/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _fetchNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read!'),
              backgroundColor: AppTheme.trustGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.loc.notifications,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppTheme.brandPurple,
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPurple))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
      ),
      floatingActionButton: _notifications.any((n) => n['read'] == false)
          ? FloatingActionButton(
              onPressed: _markAllAsRead,
              backgroundColor: AppTheme.brandPurple,
              tooltip: 'Mark All Read',
              child: const Icon(Icons.done_all, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppTheme.brandPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No new alerts or stock notifications.',
              style: TextStyle(color: AppTheme.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final theme = Theme.of(context);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final bool isRead = notification['read'] ?? false;
        final String message = notification['message'] ?? '';
        final String createdAtStr = notification['createdAt'] ?? '';
        final notificationId = notification['_id'] ?? '';

        DateTime? date;
        if (createdAtStr.isNotEmpty) {
          date = DateTime.tryParse(createdAtStr)?.toLocal();
        }
        final formattedDate = date != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead 
                ? theme.cardTheme.color ?? const Color(0xFF1E293B)
                : AppTheme.brandPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead 
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.brandPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isRead 
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.brandPurple.withValues(alpha: 0.15),
              child: Icon(
                isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                color: isRead ? AppTheme.darkGrey : AppTheme.brandPurple,
              ),
            ),
            title: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: formattedDate.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 11),
                    ),
                  )
                : null,
            trailing: !isRead
                ? InkWell(
                    onTap: () => _markAsRead(notificationId),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.done, size: 12, color: Colors.white),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
