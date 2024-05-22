import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/create_event_page.dart';

class CreateEventButton extends StatelessWidget {
  final double userRating;
  final String username;

  const CreateEventButton(
      {super.key, required this.userRating, required this.username});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreateEventPage(
                    username: username,
                  )),
        );
      },
      backgroundColor:
          Color.lerp(Colors.red, Colors.green, userRating) ?? Colors.red,
      child: const Icon(Icons.add),
    );
  }
}
