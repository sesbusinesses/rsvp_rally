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

  Color getInterpolatedColor(double value) {
    const List<Color> colors = [Colors.red, Colors.yellow, Colors.green];
    const List<double> stops = [0.0, 0.5, 1.0];

    if (value <= stops.first) return colors.first;
    if (value >= stops.last) return colors.last;

    for (int i = 0; i < stops.length - 1; i++) {
      if (value >= stops[i] && value <= stops[i + 1]) {
        final t = (value - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], t)!;
      }
    }
    return colors.last;
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    Color dynamicColor = getInterpolatedColor(rating);

    return Container(
      width: screenSize.width * 0.85,
      height: 80, // Adjusted height for better aesthetics
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.light, // Light background color
        border: Border.all(
          color: dynamicColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 5,
            offset: Offset(0, 3),
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
                    color: AppColors.dark, // Dynamic text color
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                if (widget.showUsername)
                  Text(
                    widget.username,
                    style: TextStyle(
                      color: AppColors.accent
                          .withOpacity(0.7), // Slightly lighter dynamic color
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