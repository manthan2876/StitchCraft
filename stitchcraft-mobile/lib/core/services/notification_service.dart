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
      initializationSettings,
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
      final token = await _firebaseMessaging?.getToken();
      if (token != null) {
        developer.log("FCM Device Token: $token");
        await registerDeviceTokenWithBackend(token);
      }

      // Listen for token rotation/refresh
      _firebaseMessaging?.onTokenRefresh.listen((newToken) {
        developer.log("FCM Token refreshed: $newToken");
        registerDeviceTokenWithBackend(newToken);
      });
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
      final token = directToken ?? await _firebaseMessaging?.getToken();
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
      id,
      title,
      body,
      platformChannelSpecifics,
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
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payloadString,
    );
  }

  // Handle Foreground FCM Messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      showInstantNotification(
        message.notification!.title ?? "Push Alert",
        message.notification!.body ?? "You have a new message",
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
