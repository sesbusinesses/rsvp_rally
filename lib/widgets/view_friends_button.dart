import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/friends_page.dart';

class ViewFriendsButton extends StatelessWidget {
  final String username;
  final double userRating;

  const ViewFriendsButton({
    super.key,
    required this.username,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 50,
      icon: Icon(
        Icons.account_circle,
        color: getInterpolatedColor(userRating),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendsPage(
              rating: userRating,
              username: username,
            ),
          ),
        );
      },
    );
  }
}
