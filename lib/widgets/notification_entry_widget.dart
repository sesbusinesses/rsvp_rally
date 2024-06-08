import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/time_picker.dart';

class NotificationEntryWidget extends StatefulWidget {
  final TextEditingController textController;
  final TextEditingController timeController;
  final VoidCallback onRemove;

  const NotificationEntryWidget({
    Key? key,
    required this.textController,
    required this.timeController,
    required this.onRemove,
  }) : super(key: key);

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
            DateTime? dateTime = await selectDateTime(context);
            if (dateTime != null) {
              setState(() {
                selectedDateTime = dateTime;
                widget.timeController.text = dateTime.toIso8601String();
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
