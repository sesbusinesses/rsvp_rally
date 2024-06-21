import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Initialize local notifications for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    // Combine initialization settings for both Android and iOS
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    //await getFCMToken();

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

  final firebaseFirestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> ensureTokenUploaded() async {
    final username = _currentUser!.displayName;

    bool tokenUploaded = await isTokenUploaded(username!);

    if (!tokenUploaded) {
      await uploadFcmToken();
    } else {
      //print("Token is already uploaded.");
    }
  }

  Future<bool> isTokenUploaded(String username) async {
    try {
      DocumentSnapshot snapshot =
          await firebaseFirestore.collection('Users').doc(username).get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data.containsKey('notificationToken') &&
            data['notificationToken'] != null;
      } else {
        return false;
      }
    } catch (e) {
      print("Error checking token: ${e.toString()}");
      return false;
    }
  }

  Future<void> uploadFcmToken() async {
    try {
      await FirebaseMessaging.instance.getToken().then((token) async {
        print('getToken :: $token');
        await firebaseFirestore
            .collection('Users')
            .doc(_currentUser!.displayName)
            .update({
          'notificationToken': token,
        });
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        print('onTokenRefresh :: $token');
        await firebaseFirestore
            .collection('Users')
            .doc(_currentUser!.displayName)
            .update({
          'notificationToken': token,
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  //delte when it's not in use
  Future<void> uploadFcmTokenSES() async {
    try {
      await FirebaseMessaging.instance.getToken().then((token) async {
        //print('getToken :: $token');
        await firebaseFirestore.collection('Users').doc('SES').update({
          'notificationToken': token,
        });
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        //print('onTokenRefresh :: $token');
        await firebaseFirestore.collection('Users').doc('SES').update({
          'notificationToken': token,
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Get the FCM device token
  static Future<String?> getFCMToken({int maxRetries = 3}) async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("Device Token: $token");
      return token;
    } catch (e) {
      print("Failed to get device token: $e");
      if (maxRetries > 0) {
        print("Retrying after 10 seconds...");
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
