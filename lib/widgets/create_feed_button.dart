import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/create_feed.dart'; // Make sure this import is correct

class CreateFeedButton extends StatelessWidget {
  final double userRating;
  final String username;

  const CreateFeedButton({
    super.key,
    required this.userRating,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor = getInterpolatedColor(userRating);

    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateFeedPage(
              username: username,
              rating: userRating,
            ),
          ),
        );
      },
      backgroundColor: buttonColor,
      child: const Icon(Icons.add, color: AppColors.light),
    );
  }
}
