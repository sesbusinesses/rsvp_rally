import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/notification_service.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/pages/signup_page.dart';
import 'package:rsvp_rally/pages/forgotpassword_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

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
  }

  userLogin() async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Please enter both email and password",
          style: AppColors.bodyStyle,
        ),
        backgroundColor: AppColors.accentLight,
      ));
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      final name = user?.displayName ?? 'User';

      await NotificationService().uploadFcmToken();

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => EventPage(username: name)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Incorrect Email or Password",
            style: AppColors.bodyStyle,
          ),
          backgroundColor: AppColors.accentLight,
        ));
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Invalid Email Address",
            style: AppColors.bodyStyle,
          ),
          backgroundColor: AppColors.accentLight,
        ));
      } else if (e.code == 'too-many-requests') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Too many login attempts. Try again later.",
            style: AppColors.bodyStyle,
          ),
          backgroundColor: AppColors.accentLight,
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
                height: 100,
              ),
              Text('RSVP Rally', style: AppColors.topStyle),
              const SizedBox(height: 100),
              Text(
                "Welcome back, you've been missed!",
                style: AppColors.bodyStyle,
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
                    child: Text("Forgot Password?", style: AppColors.linkStyle),
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
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppColors.bodyStyle,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()));
                    },
                    child: Text("Register now", style: AppColors.linkStyle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
