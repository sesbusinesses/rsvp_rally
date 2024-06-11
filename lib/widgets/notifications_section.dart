import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/notification_entry_widget.dart';

class NotificationsSection extends StatelessWidget {
  final double rating;
  final List<Map<String, TextEditingController>> notificationControllers;
  final VoidCallback onAddNotification;
  final Function(int) onRemoveNotification;

  const NotificationsSection({
    super.key,
    required this.rating,
    required this.notificationControllers,
    required this.onAddNotification,
    required this.onRemoveNotification,
  });

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: EdgeInsets.symmetric(
            vertical: 10, horizontal: screenSize.width * 0.05),
        width: screenSize.width * 0.95,
        decoration: BoxDecoration(
          color: AppColors.light, // Dark background color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: getInterpolatedColor(rating),
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
        child: Column(
          children: [
            const Text('Add Reminders', style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: onAddNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: getInterpolatedColor(rating),
              ),
              child: const Text('Add Reminder',
                  style: TextStyle(color: AppColors.dark)),
            ),
            ...List.generate(notificationControllers.length, (index) {
              return NotificationEntryWidget(
                textController: notificationControllers[index]['text']!,
                timeController: notificationControllers[index]['time']!,
                onRemove: () => onRemoveNotification(index),
                rating: rating,
              );
            }),
          ],
        ));
  }
}
