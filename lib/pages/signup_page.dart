import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPage> {
  String email = "",
      password = "",
      username = "",
      firstName = "",
      lastName = "";
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  final DataPusher _dataPusher = DataPusher();

  registration() async {
    // is this if really neccessary?
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(username); // Update the display name

        // Call the method from DataPusher to create a new user in Firestore
        await _dataPusher.createNewUser(username, firstName, lastName);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "Registered Successfully",
              style: TextStyle(fontSize: 20.0),
            )));

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EventPage(username: username)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "Password has to be at least 6 characters",
              style: TextStyle(fontSize: 18.0),
            )));
      } else if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "Account Already exists",
              style: TextStyle(fontSize: 18.0),
            )));
      } else if (e.code == "invalid-email") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "The email address is badly formatted",
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
            children: [
              const Text(
                "Fill your information below",
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 10.0),
              WideTextBox(
                controller: usernameController,
                hintText: "Username",
              ),
              const SizedBox(
                height: 10.0,
              ),
              WideTextBox(
                controller: firstNameController,
                hintText: "First Name",
              ),
              const SizedBox(
                height: 10.0,
              ),
              WideTextBox(
                controller: lastNameController,
                hintText: "Last Name",
              ),
              const SizedBox(
                height: 10.0,
              ),
              WideTextBox(
                controller: emailController,
                hintText: "Your Email",
              ),
              const SizedBox(
                height: 10.0,
              ),
              WideTextBox(
                controller: passwordController,
                hintText: "Your Password",
              ),
              const SizedBox(
                height: 10.0,
              ),
              WideButton(
                buttonText: 'Signup',
                onPressed: () {
                  if (_formkey.currentState!.validate()) {
                    setState(() {
                      email = emailController.text;
                      username = usernameController.text;
                      firstName = firstNameController.text;
                      lastName = lastNameController.text;
                      password = passwordController.text;
                    });
                  }
                  registration();
                },
              ),
            ],
          ),
        ),
      )),
    ]));
  }
}
