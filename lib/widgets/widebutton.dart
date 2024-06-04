import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class WideButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final double rating;

  const WideButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: getInterpolatedColor(rating),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ));
  }
}
