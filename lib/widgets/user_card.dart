import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:rsvp_rally/models/colors.dart';

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
  String? profilePicBase64;
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void didUpdateWidget(UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(widget.username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          firstName = userData['FirstName'] ?? "";
          lastName = userData['LastName'] ?? "";
          profilePicBase64 = userData['ProfilePic'] ?? null;
          rating = double.tryParse(userData['Rating'].toString()) ?? 0.0;
        });
      }
    }
  }

  String getEmoji(double rating) {
    if (rating <= 0.2) return '😡'; // Mad
    if (rating <= 0.4) return '😢'; // Sad
    if (rating <= 0.6) return '😐'; // Straight face
    if (rating <= 0.8) return '😊'; // Smiling
    return '🤩'; // Joyful
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width * 0.85,
      height: 120, // Adjusted height for consistency with ProfileEditor
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: getInterpolatedColor(rating),
          width: AppColors.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 10),  // Space between border and picture
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: profilePicBase64 != null
                      ? MemoryImage(base64Decode(profilePicBase64!))
                      : null,
                  child: profilePicBase64 == null
                      ? Icon(Icons.add, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              if (profilePicBase64 != null)
                Positioned(
                  bottom: 1,  // Adjusted for smaller CircleAvatar
                  right: -5,  // Adjusted for smaller CircleAvatar
                  child: CircleAvatar(
                    radius: 18,  // Smaller radius
                    backgroundColor: Colors.transparent,
                    child: Text(
                      getEmoji(rating),
                      style: TextStyle(fontSize: 25),  // Larger font size
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),  // Space between picture and text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$firstName $lastName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.showUsername)
                  Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
