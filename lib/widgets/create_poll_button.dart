import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/create_poll_page.dart';

class CreatePollButton extends StatelessWidget {
  final String eventID;
  final double userRating;
  final String username;

  const CreatePollButton(
      {super.key,
      required this.eventID,
      required this.userRating,
      required this.username});
      
  @override
  Widget build(BuildContext context) {
    Color buttonColor = getInterpolatedColor(userRating);

    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreatePollPage(
                    eventID: eventID,
                    username: username,
                    rating: userRating,
                  )),
        );
      },
      backgroundColor: buttonColor,
      child: const Icon(Icons.add, color: Color(0xFFfefdfd)),
    );
  }
}
