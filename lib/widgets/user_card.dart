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
      height: 80, // Adjusted height for better aesthetics
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFefd9ce), // Light background color
        border: Border.all(
          color: Color(0xFFefd9ce),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$firstName $lastName",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7161ef), // Dark text color
                ),
              ),
              if (widget.showUsername)
                Text(
                  widget.username,
                  style: TextStyle(
                    color: Color(0xFF957fef), // Medium dark text color
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFb79ced), Color(0xFF957fef)], // Gradient for rating box
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Rating: ${rating.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white, // White text color for readability
              ),
            ),
          ),
        ],
      ),
    );
  }
}
