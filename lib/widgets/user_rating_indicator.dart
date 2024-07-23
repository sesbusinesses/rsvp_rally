import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:rsvp_rally/models/colors.dart';

class UserRatingIndicator extends StatelessWidget {
  final double userRating;

  const UserRatingIndicator({super.key, required this.userRating});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 100), // Adjusted size for the semicircle
            painter: _SemicircularPainter(userRating),
          ),
          Positioned(
            top: 60, // Adjust position to align the image correctly
            child: Image.asset(
              getEmoji(userRating), // Displaying the appropriate emoji image
              width: 50,
              height: 50,
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
    final width = size.width;
    final height = size.height * 2;
    final rect = Rect.fromLTWH(0, 0, width, height);
    const startAngle = -math.pi;
    final sweepAngle = math.pi * progress;

    final gradient = const LinearGradient(
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
      stops: [
        0.0,
        1 / 6,
        2 / 6,
        3 / 6,
        4 / 6,
        5 / 6,
        1.0,
      ],
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
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

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
