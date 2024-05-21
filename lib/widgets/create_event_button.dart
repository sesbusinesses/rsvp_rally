import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/create_event_page.dart';

class CreateEventButton extends StatelessWidget {
  final double userRating;

  const CreateEventButton({super.key, required this.userRating});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateEventPage()),
        );
      },
      backgroundColor:
          Color.lerp(Colors.red, Colors.green, userRating) ?? Colors.red,
      child: const Icon(Icons.add),
    );
  }
}
