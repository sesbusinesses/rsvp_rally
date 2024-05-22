import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCard extends StatefulWidget {
  final String username;
  final bool showUsername;

  const UserCard({super.key, required this.username, this.showUsername = true});

  @override
  UserCardState createState() => UserCardState();
}

class UserCardState extends State<UserCard> {
  String firstName = "";
  String lastName = "";
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(widget.username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        firstName = userData['FirstName'] ?? "";
        lastName = userData['LastName'] ?? "";
        rating = double.tryParse(userData['Rating'].toString()) ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
      width: screenSize.width * 0.85,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: Color.lerp(Colors.red, Colors.green, rating) ?? Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Text("$firstName $lastName",
                style: TextStyle(
                    fontSize: 20,
                    color: Color.lerp(Colors.red, Colors.green, rating) ??
                        Colors.red)),
            if (widget.showUsername)
              Text(widget.username,
                  style: TextStyle(
                    color: Color.lerp(Colors.red, Colors.green, rating) ??
                        Colors.red,
                    fontSize: 16,
                  )),
          ]),
          Text("Rating: ${rating.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 16,
                  color: Color.lerp(Colors.red, Colors.green, rating) ??
                      Colors.red)),
        ],
      ),
    );
  }
}
