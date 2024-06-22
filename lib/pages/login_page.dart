// ignore_for_file: use_build_context_synchronously

import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/notification_service.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/pages/signup_page.dart';
import 'package:rsvp_rally/pages/forgotpassword_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

bool isNavigating = false;

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInState();
}

class _LogInState extends State<LogInPage> {
  String email = "", password = "";

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();
  bool isLogin = false;

  @override
  void initState() {
    super.initState();
    checkIfLogin();
  }

  void checkIfLogin() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null && mounted && !isNavigating) {
        final name = user.displayName ?? 'User';

        await NotificationService().ensureTokenUploaded();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EventPage(username: name)),
        );
      }
    });
  }

  userLogin() async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Please enter both email and password",
          style: TextStyle(fontSize: 18.0, color: AppColors.dark),
        ),
      ));
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      final name = user?.displayName ?? 'User';

      await NotificationService().ensureTokenUploaded();

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => EventPage(username: name)));
      }
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Incorrect Email or Password",
            style: TextStyle(fontSize: 18.0, color: AppColors.dark),
          ),
        ));
      } else if (e.code == 'invalid-email' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Invalid Email Address",
            style: TextStyle(fontSize: 18.0, color: AppColors.dark),
          ),
        ));
      } else if (e.code == 'too-many-requests' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Too many login attempts. Try again later.",
            style: TextStyle(fontSize: 18.0, color: AppColors.dark),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            vertical: 50.0, horizontal: screenSize.width * 0.075),
        child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 80,
              ),
              Image(
                  image: const AssetImage('assets/rsvp_rally.png'),
                  width: screenSize.width * 0.5),
              const SizedBox(height: 70),
              const Text(
                "Welcome back, you've been missed!",
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 10.0),
              WideTextBox(
                controller: useremailcontroller,
                hintText: "Your Email",
              ),
              const SizedBox(height: 10.0),
              WideTextBox(
                controller: userpasswordcontroller,
                hintText: "Your Password",
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPassword()));
                    },
                    child: const Text("Forgot Password?",
                        style: TextStyle(
                          color: AppColors.link,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        )),
                  )
                ],
              ),
              const SizedBox(height: 12.0),
              WideButton(
                  buttonText: 'Login',
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        email = useremailcontroller.text;
                        password = userpasswordcontroller.text;
                      });
                    }
                    userLogin();
                  }),
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 16.0, color: AppColors.dark),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isNavigating = true;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()));
                    },
                    child: const Text("Register now",
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
    );
  }
}
