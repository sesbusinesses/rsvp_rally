import 'package:flutter/material.dart';

class BracketPainter extends CustomPainter {
  final Color color;

  BracketPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.5, size.height * 0.25);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.4, 0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6,
        size.width * 0.5, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
