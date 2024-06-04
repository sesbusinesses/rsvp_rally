import 'package:flutter/material.dart';

class RatingIndicator extends StatelessWidget {
  final double progress;

  const RatingIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(10.0), // Adjust the corner radius as needed
      child: CustomPaint(
        size: const Size(100, 20), // Adjust size as needed
        painter: _RatingIndicatorPainter(progress),
      ),
    );
  }
}

class _RatingIndicatorPainter extends CustomPainter {
  final double progress;

  _RatingIndicatorPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final progressWidth = size.width * progress;

    final gradient = const LinearGradient(
      colors: [Colors.red, Colors.yellow, Colors.green],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    // Draw the background rectangle
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw full background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect,
          const Radius.circular(10.0)), // Adjust the corner radius as needed
      backgroundPaint,
    );

    // Draw the progress rectangle
    final progressRect = Rect.fromLTWH(0, 0, progressWidth, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(progressRect,
          const Radius.circular(10.0)), // Adjust the corner radius as needed
      paint,
    );
  }

  @override
  bool shouldRepaint(_RatingIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
