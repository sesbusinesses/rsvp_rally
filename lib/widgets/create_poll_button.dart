import 'package:flutter/material.dart';
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
