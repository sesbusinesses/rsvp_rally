import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:rsvp_rally/models/colors.dart';

class UserRatingIndicator extends StatelessWidget {
  final double userRating;

  const UserRatingIndicator({super.key, required this.userRating});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRatingInfoDialog(context),
      child: Container(
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
      ),
    );
  }

  String getEmoji(double rating) {
    if (rating <= 1 / 7) return 'assets/images/octopus.png'; // Worm (Red)
    if (rating <= 2 / 7) return 'assets/images/squid.png'; // Shrimp (Orange)
    if (rating <= 3 / 7) return 'assets/images/bumblebee.png'; // Bumblebee (Yellow)
    if (rating <= 4 / 7) return 'assets/images/turtle.png'; // Turtle (Green)
    if (rating <= 5 / 7) return 'assets/images/whale.png'; // Whale (Blue)
    if (rating <= 6 / 7) return 'assets/images/dinosaur.png'; // Jellyfish (Indigo)
    return 'assets/images/unicorn.png'; // Unicorn (Violet/Purple)
  }

  void _showRatingInfoDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Rating Info",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            height: 400,
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rating Icons and Requirements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildRatingInfoRow(context, 'assets/images/octopus.png', '0.0 - Everyone Starts Out'),
                  _buildRatingInfoRow(context, 'assets/images/squid.png', '0.15 - Sussy Squid'),
                  _buildRatingInfoRow(context, 'assets/images/bumblebee.png', '0.29 - A Busy Little Bee'),
                  _buildRatingInfoRow(context, 'assets/images/turtle.png', '0.43 - Timid Turtle'),
                  _buildRatingInfoRow(context, 'assets/images/whale.png', '0.58 - Wacky Whale'),
                  _buildRatingInfoRow(context, 'assets/images/dinosaur.png', '0.72 - Diabolical Dino'),
                  _buildRatingInfoRow(context, 'assets/images/unicorn.png', '0.86 - A Truly Rare Unicorn'),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  Widget _buildRatingInfoRow(BuildContext context, String assetPath, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.asset(
            assetPath,
            width: 30,
            height: 30,
          ),
          SizedBox(width: 10),
          Text(range),
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
