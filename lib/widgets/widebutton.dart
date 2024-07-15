import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class WideButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final double? rating;
  final bool smallVersion;

  const WideButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.rating,
    this.smallVersion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding:
              smallVersion ? const EdgeInsets.all(5) : const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color:
                  rating != null ? getInterpolatedColor(rating!) : Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ]),
          child: Center(
            child: Text(buttonText,
                style: AppColors.buttonStyle
                    .copyWith(color: getTextOnRatingColor(rating ?? 0))),
          ),
        ),
      ),
    );
  }
}
