import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'assets/logo.jpeg',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 40),
        const Text(
          'Hello again!',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Welcome back, you\'ve been missed!',
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 40),
        WideTextBox(
          hintText: 'Username',
          controller: _usernameController,
        ),
        const SizedBox(height: 10),
        WideTextBox(
          hintText: 'Password',
          controller: _passwordController,
        ),
        const SizedBox(height: 30),
        WideButton(
          buttonText: 'Sign In',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventPage()),
            );
            fetchDataFromFirestore();
          },
        ),
        const SizedBox(height: 25),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Not a member?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Register now',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
      ]),
    );
  }
}
