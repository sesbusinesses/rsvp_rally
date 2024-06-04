import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/friends_page.dart';

class ViewFriendsButton extends StatelessWidget {
  final String username;
  final double userRating;

  const ViewFriendsButton({
    super.key,
    required this.username,
    required this.userRating,
  });

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
    Color iconColor = getInterpolatedColor(userRating);

    return IconButton(
      iconSize: 50,
      icon: Icon(
        Icons.account_circle,
        color: iconColor,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendsPage(
              username: username,
            ),
          ),
        );
      },
    );
  }
}
