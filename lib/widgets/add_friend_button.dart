import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class AddFriendsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddFriendsButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: IconButton(
          icon: Icon(Icons.person_add),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
