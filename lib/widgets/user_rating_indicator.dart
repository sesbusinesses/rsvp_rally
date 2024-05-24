import 'package:flutter/material.dart';
import 'dart:math' as math;

class UserRatingIndicator extends StatelessWidget {
  final double userRating;

  const UserRatingIndicator({super.key, required this.userRating});

  @override
  Widget build(BuildContext context) {
    // Determine the emoji based on the user rating
    String getEmoji(double rating) {
      if (rating <= 0.2) return '😡'; // Mad
      if (rating <= 0.4) return '😢'; // Sad
      if (rating <= 0.6) return '😐'; // Straight face
      if (rating <= 0.8) return '😊'; // Smiling
      return '🤩'; // Joyful
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(200, 200),
            painter: _SemicircularPainter(userRating),
          ),
          Positioned(
            top: 50,
            child: Text(
              getEmoji(userRating), // Displaying the appropriate emoji
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemicircularPainter extends CustomPainter {
  final double progress;

  _SemicircularPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -math.pi;
    final sweepAngle = math.pi * progress;

    final gradient = LinearGradient(
      colors: [Colors.red, Colors.yellow, Colors.green],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Draw the background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    // Draw full semicircle background
    canvas.drawArc(rect, startAngle, math.pi, false, backgroundPaint);

    // Draw the progress arc
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_SemicircularPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
