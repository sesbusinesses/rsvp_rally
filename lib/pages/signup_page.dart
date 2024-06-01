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
  String email = "", password = "", name = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  final DataPusher _dataPusher = DataPusher();

  registration() async {
    if (password != null && password.length >= 6) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Call the method from DataPusher to create a new user in Firestore
        await _dataPusher.createNewUser(userCredential.user!.uid, name, email);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "Registered Successfully",
              style: TextStyle(fontSize: 20.0),
            )));
        // ignore: use_build_context_synchronously
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => EventPage(username: name)));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Password Provided is too Weak",
                style: TextStyle(fontSize: 18.0),
              )));
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
      backgroundColor: const Color(0xFF5f42b2),
      body: SingleChildScrollView(
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              Container(
                margin:
                    const EdgeInsets.only(top: 130.0, left: 20.0, right: 20.0),
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
                      height: 50.0,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3.0, horizontal: 5.0),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 147, 126, 207),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        controller: namecontroller,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Name';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.person_2_outlined,
                              color: Colors.white,
                            ),
                            hintText: 'Your username',
                            hintStyle: TextStyle(color: Colors.white60)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3.0, horizontal: 5.0),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 147, 126, 207),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        controller: mailcontroller,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter E-mail';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.white,
                            ),
                            hintText: 'Your E-mail',
                            hintStyle: TextStyle(color: Colors.white60)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3.0, horizontal: 5.0),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 147, 126, 207),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        obscureText: true,
                        controller: passwordcontroller,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Password';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.password_outlined,
                              color: Colors.white,
                            ),
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.white60)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      height: 80.0,
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (_formkey.currentState!.validate()) {
                          setState(() {
                            email = mailcontroller.text;
                            name = namecontroller.text;
                            password = passwordcontroller.text;
                          });
                        }
                        registration();
                      },
                      child: Center(
                        child: Container(
                          width: 150,
                          height: 55,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf95f3b),
                              borderRadius: BorderRadius.circular(30)),
                          child: const Center(
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
              SizedBox(
                height: MediaQuery.of(context).size.height / 6,
              ),
              Row(
                children: [
                  const Spacer(),
                  const Text(
                    "Already Have Account?",
                    style: TextStyle(color: Colors.white, fontSize: 17.0),
                  ),
                  const SizedBox(
                    width: 5.0,
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const LogInPage())); //maybe just unpush instead?
                      },
                      child: const Text(
                        " Login",
                        style: TextStyle(
                            color: Color(0xFFf95f3b),
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold),
                      )),
                  const Spacer(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
