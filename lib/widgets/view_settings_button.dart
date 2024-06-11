import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/settings_page.dart';

class ViewSettingsButton extends StatelessWidget {
  final String username;
  final double userRating;

  const ViewSettingsButton({
    super.key,
    required this.username,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 50,
      icon: Icon(
        Icons.settings,
        color: getInterpolatedColor(userRating),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              userRating: userRating,
              username: username,
            ),
          ),
        );
      },
    );
  }
}
