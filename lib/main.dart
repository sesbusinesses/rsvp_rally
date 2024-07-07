import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsvp_rally/models/notification_service.dart';
import 'package:rsvp_rally/models/route_observer.dart';
import 'package:rsvp_rally/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack, overlays: [
      SystemUiOverlay.top,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LogInPage(),
      navigatorObservers: [
        routeObserver
      ], // Add the RouteObserver to the MaterialApp
    );
  }
}
