import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    // Initialize local notifications for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await getFCMToken();
    print('got token');

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Configure foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received when the app is in the foreground:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      _showNotification(
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body',
      );
    });

    // Configure background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Subscribe to a topic
    await _firebaseMessaging.subscribeToTopic('all');
  }

  // get the fcm device token
  static Future<String?> getFCMToken({int maxRetries = 3}) async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("for android device Token: $token");
      return token;
    } catch (e) {
      print("failed to get device token");
      if (maxRetries > 0) {
        print("try after 10 sec");
        await Future.delayed(const Duration(seconds: 10));
        return getFCMToken(maxRetries: maxRetries - 1);
      } else {
        return null;
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'Default channel for notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();

    print('Message received when the app is in the background:');

    NotificationService notificationService = NotificationService();
    notificationService._showNotification(
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
    );
  }
}
