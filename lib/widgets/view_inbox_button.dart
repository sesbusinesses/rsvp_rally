import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/inbox_page.dart';

class ViewInboxButton extends StatelessWidget {
  final String username;
  final double userRating;

  const ViewInboxButton({
    super.key,
    required this.username,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 50,
      icon: Icon(
        Icons.mail,
        color: getInterpolatedColor(userRating),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InboxPage(
              userRating: userRating,
              username: username,
            ),
          ),
        );
      },
    );
  }
}
