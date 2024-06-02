import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/notification_entry_widget.dart';

class NotificationsSection extends StatelessWidget {
  final List<Map<String, TextEditingController>> notificationControllers;
  final VoidCallback onAddNotification;
  final Function(int) onRemoveNotification;

  const NotificationsSection({
    super.key,
    required this.notificationControllers,
    required this.onAddNotification,
    required this.onRemoveNotification,
  });

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: screenSize.width * 0.85,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('Add Reminders', style: TextStyle(fontSize: 20)),
            TextButton(
                onPressed: onAddNotification,
                child: const Text('Add Reminder')),
            ...List.generate(notificationControllers.length, (index) {
              return NotificationEntryWidget(
                textController: notificationControllers[index]['text']!,
                timeController: notificationControllers[index]['time']!,
                onRemove: () => onRemoveNotification(index),
              );
            }),
          ],
        ));
  }
}
