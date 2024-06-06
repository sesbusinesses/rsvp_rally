import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/login_page.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

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
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: 50.0, horizontal: screenSize.width * 0.075),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                const Text(
                  "Password Recovery",
                  style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 100.0),
                WideTextBox(
                  controller: mailcontroller,
                  hintText: "Enter your email address",
                ),
                const SizedBox(height: 20.0),
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
                const SizedBox(height: 200.0),
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LogInPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    "LogIn",
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 18.0, color: AppColors.dark),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EventPage(username: 'bossman5960')));
                      },
                      child: const Text("Create\n(bossman)",
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500,
                          )),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
