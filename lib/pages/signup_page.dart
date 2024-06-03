import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_pusher.dart';

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
    if (password != null) {
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Password Provided is too Weak",
                style: TextStyle(fontSize: 18.0),
              )));
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Account Already exists",
                style: TextStyle(fontSize: 18.0),
              )));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5f42b2),
      body: SingleChildScrollView(
        child: Container(
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello...!",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36.0,
                            fontFamily: 'Pacifico'),
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      buildTextFormField(
                        controller: usernameController,
                        hintText: 'Your username',
                        icon: Icons.person_2_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Username';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      buildTextFormField(
                        controller: firstNameController,
                        hintText: 'Your First Name',
                        icon: Icons.edit,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter First Name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      buildTextFormField(
                        controller: lastNameController,
                        hintText: 'Your Last Name',
                        icon: Icons.edit,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Last Name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      buildTextFormField(
                        controller: emailController,
                        hintText: 'Your E-mail',
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter E-mail';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      buildTextFormField(
                        controller: passwordController,
                        hintText: 'Password',
                        icon: Icons.password_outlined,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Password';
                          }

                          return null;
                        },
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      GestureDetector(
                        onTap: () async {
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
                        child: Center(
                          child: Container(
                            width: 150,
                            height: 50,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Color(0xFFf95f3b),
                                borderRadius: BorderRadius.circular(30)),
                            child: Center(
                                child: Text(
                              "Signup",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold),
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.0 //MediaQuery.of(context).size.height / 8,
                    ),
                Row(
                  children: [
                    Spacer(),
                    Text(
                      "Already Have Account?",
                      style: TextStyle(color: Colors.white, fontSize: 17.0),
                    ),
                    SizedBox(
                      width: 5.0,
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LogInPage()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          " Login",
                          style: TextStyle(
                              color: Color(0xFFf95f3b),
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        )),
                    Spacer(),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 147, 126, 207),
          borderRadius: BorderRadius.circular(30)),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
              icon,
              color: Colors.white,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white60)),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
