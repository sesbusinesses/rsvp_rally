import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/create_feed.dart'; // Make sure this import is correct

class CreateFeedButton extends StatelessWidget {
  final double userRating;
  final String username;

  const CreateFeedButton({
    Key? key,
    required this.userRating,
    required this.username,
  }) : super(key: key);

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
