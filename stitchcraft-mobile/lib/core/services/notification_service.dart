import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:stitchcraft/core/services/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;

  FirebaseMessaging? get _firebaseMessaging {
    if (isMobile) {
      return FirebaseMessaging.instance;
    }
    return null;
  }

  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // Initialize notifications
  Future<void> init() async {
    if (!isMobile) {
      developer.log("Notification initialization skipped: not on mobile platform.");
      return;
    }

    // 1. Initialize Timezone for scheduling
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      developer.log("Timezone set to Asia/Kolkata");
    } catch (e) {
      developer.log("Could not set timezone: $e");
    }

    // 2. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const AndroidNotificationChannel importanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      'scheduled_channel',
      'Scheduled Notifications',
      description: 'This channel is used for scheduled reminders.',
      importance: Importance.max,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(importanceChannel);
    await androidPlugin?.createNotificationChannel(scheduledChannel);

    // 4. Request Permissions
    await requestPermissions();

    // 5. FCM Setup & Listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 6. Handle Terminated App Launch from Notification
    try {
      final initialMessage = await _firebaseMessaging?.getInitialMessage();
      if (initialMessage != null) {
        developer.log("App launched from terminated state via FCM: ${initialMessage.data}");
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleNotificationClick(initialMessage);
        });
      }
    } catch (e) {
      developer.log("Error checking initial FCM message: $e");
    }

    // 7. Get and Register Device Token with Backend
    try {
      _firebaseMessaging?.onRegistered.listen((token) {
        developer.log("FCM Token registered: $token");
        _currentToken = token;
        registerDeviceTokenWithBackend(token);
      });
      await _firebaseMessaging?.register();
    } catch (e) {
      developer.log("Error getting/registering FCM Token: $e");
    }
  }

  Future<void> requestPermissions() async {
    if (!isMobile) return;

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _firebaseMessaging?.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Register FCM device token with backend REST service
  Future<void> registerDeviceTokenWithBackend([String? directToken]) async {
    try {
      String? token = directToken ?? _currentToken;
      if (token == null || token.isEmpty) {
        try {
          final registrationFuture = _firebaseMessaging?.onRegistered.first.timeout(
            const Duration(seconds: 5),
          );
          await _firebaseMessaging?.register();
          token = await registrationFuture;
          _currentToken = token;
        } catch (_) {}
      }
      if (token == null || token.isEmpty) return;

      final authToken = await AuthService().getToken();
      if (authToken == null || authToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/notifications/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        developer.log('FCM token registered with backend successfully.', name: 'NotificationService');
      }
    } catch (e) {
      developer.log('Failed to register FCM token with backend: $e', name: 'NotificationService');
    }
  }

  // Show Instant Notification
  Future<void> showInstantNotification(
    String title,
    String body, {
    int id = 0,
    Map<String, dynamic>? payloadData,
  }) async {
    if (!isMobile) {
      developer.log("Notification skipped: not on mobile platform.");
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final payloadString = payloadData != null ? json.encode(payloadData) : null;

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payloadString,
    );
  }

  // Schedule Notification
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    int seconds, {
    Map<String, dynamic>? payloadData,
  }) async {
    if (!isMobile) {
      developer.log("Notification skipped: not on mobile platform.");
      return;
    }

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    final payloadString = payloadData != null ? json.encode(payloadData) : null;

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payloadString,
    );
  }

  /// Schedule Order Due Date Reminders (Both 1 day before AND on the morning of delivery)
  Future<void> scheduleOrderDueReminders({
    required String orderId,
    required String customerName,
    required String garmentType,
    required DateTime dueDate,
  }) async {
    if (!isMobile) return;

    final now = DateTime.now();

    // 1. Reminder: 1 Day Before Due Date (scheduled for 9:00 AM)
    final oneDayBefore = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9, 0);
    if (oneDayBefore.isAfter(now)) {
      final seconds = oneDayBefore.difference(now).inSeconds;
      final notifId = (orderId.hashCode ^ 0x01).abs();
      await scheduleNotification(
        notifId,
        '⏰ Order Due Tomorrow',
        'Order for $customerName ($garmentType) is due tomorrow!',
        seconds,
        payloadData: {'orderId': orderId, 'type': 'order_due_reminder'},
      );
      developer.log("Scheduled 1-day before reminder for order $orderId in ${seconds}s", name: 'NotificationService');
    }

    // 2. Reminder: Morning of Due Date (scheduled for 9:00 AM)
    final morningOfDue = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
    if (morningOfDue.isAfter(now)) {
      final seconds = morningOfDue.difference(now).inSeconds;
      final notifId = (orderId.hashCode ^ 0x02).abs();
      await scheduleNotification(
        notifId,
        '🚨 Order Due Today!',
        'Order for $customerName ($garmentType) is scheduled for delivery today.',
        seconds,
        payloadData: {'orderId': orderId, 'type': 'order_due_reminder'},
      );
      developer.log("Scheduled day-of reminder for order $orderId in ${seconds}s", name: 'NotificationService');
    }
  }

  /// Cancel reminders when an order is completed, delivered, or cancelled
  Future<void> cancelOrderDueReminders(String orderId) async {
    if (!isMobile) return;
    await cancelNotification((orderId.hashCode ^ 0x01).abs());
    await cancelNotification((orderId.hashCode ^ 0x02).abs());
  }

  /// Cancel a single local notification by id
  Future<void> cancelNotification(int id) async {
    if (!isMobile) return;
    try {
      await _localNotificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  // Handle Foreground FCM Messages - only show instant banners for allowed device push types
  void _handleForegroundMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString();
    final isAllowedPush = type == 'low_stock' || type == 'order_due_reminder';

    if (isAllowedPush && message.notification != null) {
      showInstantNotification(
        message.notification!.title ?? "StitchCraft Alert",
        message.notification!.body ?? "Alert",
        payloadData: message.data,
      );
    }
  }

  // Handle Notification Taps (Local)
  void _onNotificationTapped(NotificationResponse response) {
    developer.log("Notification Tapped: ${response.payload}", name: 'NotificationService');
    if (response.payload == null || response.payload!.isEmpty) {
      _navigateTo('/notifications');
      return;
    }

    try {
      final decoded = json.decode(response.payload!);
      if (decoded is Map<String, dynamic>) {
        _navigateFromPayload(decoded);
        return;
      }
    } catch (_) {}

    _navigateTo('/notifications');
  }

  // Handle Notification Clicks (FCM Background/Terminated)
  void _handleNotificationClick(RemoteMessage message) {
    developer.log("FCM Message Clicked: ${message.data}", name: 'NotificationService');
    _navigateFromPayload(message.data);
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final orderId = data['orderId'] ?? data['order_id'];
    if (orderId != null && orderId.toString().isNotEmpty) {
      _navigateTo('/order_details', arguments: orderId.toString());
      return;
    }

    final customerId = data['customerId'] ?? data['customer_id'];
    if (customerId != null && customerId.toString().isNotEmpty) {
      _navigateTo('/customer_details', arguments: customerId.toString());
      return;
    }

    _navigateTo('/notifications');
  }

  void _navigateTo(String routeName, {Object? arguments}) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamed(routeName, arguments: arguments);
    }
  }
}
