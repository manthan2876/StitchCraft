import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
      print("Notification initialization skipped: not on mobile platform.");
      return;
    }

    // 1. Initialize Timezone for scheduling
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      print("Timezone set to Asia/Kolkata");
    } catch (e) {
      print("Could not set timezone: $e");
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
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      'scheduled_channel', // id
      'Scheduled Notifications', // title
      description: 'This channel is used for scheduled reminders.',
      importance: Importance.max,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(importanceChannel);
    await androidPlugin?.createNotificationChannel(scheduledChannel);

    // 4. Request Permissions (Android 13+)
    await requestPermissions();

    // 5. FCM Setup
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    
    // Get Device Token (Optional: for testing push)
    try {
      String? token = await _firebaseMessaging?.getToken();
      print("FCM Device Token: $token");
    } catch (e) {
      print("Error getting FCM Token: $e");
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

  // Show Instant Notification
  Future<void> showInstantNotification(String title, String body, {int id = 0}) async {
    if (!isMobile) {
      print("Notification skipped: not on mobile platform.");
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

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'lab_10_target',
    );
  }

  // Schedule Notification
  Future<void> scheduleNotification(
      int id, String title, String body, int seconds) async {
    if (!isMobile) {
      print("Notification skipped: not on mobile platform.");
      return;
    }

    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    
    print("Scheduling notification (id: $id) for: $scheduledTime (Current local time: ${tz.TZDateTime.now(tz.local)})");

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
      payload: 'scheduled_payload',
    );
  }

  // Handle Foreground FCM Messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      showInstantNotification(
        message.notification!.title ?? "Push Alert",
        message.notification!.body ?? "You have a new message",
      );
    }
  }

  // Handle Notification Taps (Local)
  void _onNotificationTapped(NotificationResponse response) {
    print("Notification Tapped: ${response.payload}");
  }

  // Handle Notification Clicks (FCM Background/Terminated)
  void _handleNotificationClick(RemoteMessage message) {
    print("FCM Message Clicked: ${message.data}");
  }
}
