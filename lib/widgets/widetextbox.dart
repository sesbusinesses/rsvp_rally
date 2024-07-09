import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class WideTextBox extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const WideTextBox({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: TextFormField(
          controller: controller,
          onChanged: onChanged,
          style: AppColors.bodyStyle,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.multiline,
          maxLines:
              null, // This allows the input to grow as long as the user types
          minLines: 1, // Minimum line count for the text field
        ),
      ),
    );
  }
}
