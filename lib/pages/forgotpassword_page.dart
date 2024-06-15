// ignore_for_file: use_build_context_synchronously

import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

Future<void> logAllUsers() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    QuerySnapshot querySnapshot = await firestore.collection('Users').get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      developer.log('User ID: ${doc.id}, User Data: $userData');
    }
  } catch (e) {
    developer.log('Error fetching users collection: $e');
  }
}

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String email = "";
  TextEditingController mailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
        "Password Reset Email has been sent!",
        style: TextStyle(fontSize: 18.0),
      )));
      // Optionally navigate to login page
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "No user found for that email.",
          style: TextStyle(fontSize: 18.0),
        )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(children: [
      AppBar(),
      Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: 50.0, horizontal: screenSize.width * 0.075),
          child: Form(
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image(
                    image: const AssetImage('assets/rsvp_rally.png'),
                    width: screenSize.width * 0.5),
                const SizedBox(height: 70),
                const Text(
                  "Recover your password below",
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                WideTextBox(
                  controller: mailcontroller,
                  hintText: "Enter your email address",
                ),
                const SizedBox(height: 10.0),
                WideButton(
                  buttonText: 'Send Password Reset Email',
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        email = mailcontroller.text;
                      });
                      resetPassword();
                    }
                  },
                ),
                const SizedBox(height: 120),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EventPage(username: 'SES')));
                        logAllUsers();
                      },
                      child: const Text("Login as SES",
                          style: TextStyle(
                            color: AppColors.link,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ]));
  }
}
