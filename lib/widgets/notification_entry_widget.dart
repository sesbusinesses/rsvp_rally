import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class NotificationEntryWidget extends StatelessWidget {
  final TextEditingController textController;
  final TextEditingController timeController;
  final VoidCallback onRemove;

  const NotificationEntryWidget({
    super.key,
    required this.textController,
    required this.timeController,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WideTextBox(hintText: 'Notification Text', controller: textController),
        WideTextBox(hintText: 'Notification Time', controller: timeController),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
