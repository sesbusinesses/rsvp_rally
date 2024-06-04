import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/pages/signup_page.dart';
import 'package:rsvp_rally/pages/forgotpassword_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInState();
}

class _LogInState extends State<LogInPage> {
  String email = "", password = "";

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = new TextEditingController();
  TextEditingController userpasswordcontroller = new TextEditingController();

  userLogin() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      final name = user?.displayName ?? 'User';

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => EventPage(username: name)));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "No User Found for that Email",
            style: TextStyle(fontSize: 18.0, color: Colors.black),
          ),
        ));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
          "Wrong Password Provided by User",
          style: TextStyle(fontSize: 18.0, color: Colors.black),
        )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5f42b2),
      body: SingleChildScrollView(
        child: Container(
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  "assets/logo.jpeg",
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2.9,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    "Welcome\nBack",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34.0,
                        fontFamily: 'Pacifico'),
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 147, 126, 207),
                      borderRadius: BorderRadius.circular(22)),
                  child: TextFormField(
                    controller: useremailcontroller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Email';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.email,
                          color: Colors.white,
                        ),
                        hintText: 'Your Email',
                        hintStyle: TextStyle(color: Colors.white60)),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 147, 126, 207),
                      borderRadius: BorderRadius.circular(22)),
                  child: TextFormField(
                    controller: userpasswordcontroller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.password,
                          color: Colors.white,
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.white60)),
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPassword()));
                  },
                  child: Container(
                    padding: EdgeInsets.only(right: 24.0),
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30.0,
                ),
                GestureDetector(
                  onTap: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        email = useremailcontroller.text;
                        password = userpasswordcontroller.text;
                      });
                    }
                    userLogin();
                  },
                  child: Center(
                    child: Container(
                      width: 150,
                      height: 55,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Color(0xFFf95f3b),
                          borderRadius: BorderRadius.circular(30)),
                      child: Center(
                          child: Text(
                        "Login",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold),
                      )),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New User?",
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
                    SizedBox(
                      width: 5.0,
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()));
                        },
                        child: Text(
                          " Signup",
                          style: TextStyle(
                              color: Color(0xFFf95f3b),
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
