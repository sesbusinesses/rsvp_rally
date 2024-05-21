import 'package:flutter/material.dart';
import 'package:semicircle_indicator/semicircle_indicator.dart';

class UserRatingIndicator extends StatelessWidget {
  final double userRating;

  const UserRatingIndicator({super.key, required this.userRating});

  @override
  Widget build(BuildContext context) {
    return SemicircularIndicator(
      color: Color.lerp(Colors.red, Colors.green, userRating) ?? Colors.red,
      bottomPadding: 15,
      progress: userRating,
      child: Text(
        '${(userRating * 100).toStringAsFixed(0)}%', // Displaying the rating as a percentage
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color.lerp(Colors.red, Colors.green, userRating) ?? Colors.red,
        ),
      ),
    );
  }
}
