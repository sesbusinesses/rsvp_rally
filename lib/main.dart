import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rsvp_rally/pages/main_page_view.dart';
import 'firebase_options.dart';
import 'package:rsvp_rally/models/notification_service.dart';
import 'package:rsvp_rally/models/route_observer.dart';
import 'package:rsvp_rally/pages/login_page.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        routeObserver
      ], // Add the RouteObserver to the MaterialApp
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return MainPageView(username: user.displayName ?? 'User');
        } else {
          return const LogInPage();
        }
      },
    );
  }
}
