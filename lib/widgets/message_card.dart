import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class MessageCard extends StatefulWidget {
  final String username;
  final double rating;
  final String message;

  const MessageCard({
    super.key,
    required this.username,
    required this.rating,
    required this.message,
  });

  @override
  MessageCardState createState() => MessageCardState();
}

class MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
      width: screenSize.width * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.light, // Dark background color
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: getInterpolatedColor(widget.rating),
          width: AppColors.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: IntrinsicHeight(
          child: IntrinsicWidth(
            child: Text(
              widget.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
