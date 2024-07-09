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
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> initialize() async {
    // Request permissions for Android.

    if (Platform.isAndroid) {
      await _firebaseMessaging.requestPermission();
      // Initialize local notifications for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: initializationSettingsAndroid),
      );
    }

    // Request permissions for IOS.
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
      // Initialize local notifications for iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      // Combine initialization settings for both Android and iOS
      const InitializationSettings initializationSettings =
          InitializationSettings(
        iOS: initializationSettingsIOS,
      );
    }

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
    //await _firebaseMessaging.subscribeToTopic('all');
  }

  Future<void> ensureTokenUploaded() async {
    final String? username = _currentUser?.displayName;
    if (username == null) return;
    final String? token = await FirebaseMessaging.instance.getToken();

    bool tokenUploaded = await isTokenUploaded(username, token);
    if (!tokenUploaded) {
      await uploadFcmToken();
    } else {
      print("Token is already uploaded.");
    }
  }

  Future<bool> isTokenUploaded(String username, String? token) async {
    try {
      if (token == null) {
        print("FCM token is null.");
        return false;
      }
      DocumentSnapshot snapshot =
          await firebaseFirestore.collection('Users').doc(username).get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data.containsKey('notificationToken') &&
            data['notificationToken'].contains(token);
      }
      return false;
    } catch (e) {
      print("Error checking token: ${e.toString()}");
      return false;
    }
  }

  Future<void> uploadFcmToken() async {
    try {
      await FirebaseMessaging.instance.getToken().then((token) async {
        if (token == null) return;
        print('getToken :: $token');
        await firebaseFirestore
            .collection('Users')
            .doc(_currentUser?.displayName)
            .update({
          'notificationToken': FieldValue.arrayUnion([token])
        });
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        print('onTokenRefresh :: $token');
        await firebaseFirestore
            .collection('Users')
            .doc(_currentUser?.displayName)
            .update({
          'notificationToken': FieldValue.arrayUnion([token])
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> signOut() async {
    String? username = _currentUser?.displayName;
    if (username != null) {
      final String? token = await FirebaseMessaging.instance.getToken();
      DocumentReference userRef =
          firebaseFirestore.collection('Users').doc(username);

      if (token != null) {
        // Only remove the current device's token from the array
        await userRef.update({
          'notificationToken': FieldValue.arrayRemove([token])
        });
      }

      await FirebaseAuth.instance.signOut();
      // Since this is a service class, navigation isn't handled here, might need to be triggered elsewhere.
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

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'Default_Sound');
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Message received when the app is in the background:');
    NotificationService notificationService = NotificationService();
    notificationService._showNotification(
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body');
  }
}
