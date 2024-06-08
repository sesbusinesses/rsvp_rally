import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/rating_indicator.dart';

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
        color: AppColors.light, // Dark background color
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$firstName $lastName",
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.dark, // Dark text color
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                if (widget.showUsername)
                  Text(
                    widget.username,
                    style: TextStyle(
                      color: AppColors.accent
                          .withOpacity(0.7), // Slightly lighter accent color
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
              ],
            ),
          ),
          RatingIndicator(progress: rating),
        ],
      ),
    );
  }
}
