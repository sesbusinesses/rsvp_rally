import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/time_picker.dart';

class NotificationEntryWidget extends StatefulWidget {
  final double rating;
  final TextEditingController textController;
  final TextEditingController timeController;
  final VoidCallback onRemove;

  const NotificationEntryWidget({
    super.key,
    required this.rating,
    required this.textController,
    required this.timeController,
    required this.onRemove,
  });

  @override
  _NotificationEntryWidgetState createState() =>
      _NotificationEntryWidgetState();
}

class _NotificationEntryWidgetState extends State<NotificationEntryWidget> {
  DateTime? selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WideTextBox(
            hintText: 'Notification Text', controller: widget.textController),
        InkWell(
          onTap: () async {
            print('selecting date time');
            DateTime? dateTime = await selectDateTime(context, widget.rating);
            print('dateTime is $dateTime');
            if (dateTime != null) {
              setState(() {
                selectedDateTime = dateTime;
                print(
                    'setting timeController to ${dateTime.toIso8601String()}');
                widget.timeController.text = dateTime.toIso8601String();
                print('timeController is now ${widget.timeController.text}');
              });
            }
          },
          child: IgnorePointer(
            child: WideTextBox(
              hintText: 'Notification Time',
              controller: widget.timeController,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}
