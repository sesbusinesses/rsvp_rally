import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/bracket_painter.dart';
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
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: widget.onRemove,
        ),
        CustomPaint(
          size: const Size(20, 100),
          painter: BracketPainter(getInterpolatedColor(widget.rating)),
        ),
        Expanded(
          child: Column(
            children: [
              WideTextBox(
                hintText: 'Notification Text',
                controller: widget.textController,
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: () async {
                  DateTime? dateTime =
                      await selectDateTime(context, widget.rating, null);
                  if (dateTime != null) {
                    setState(() {
                      selectedDateTime = dateTime;
                      widget.timeController.text =
                          DateFormat('MMM d, yyyy h:mm a').format(dateTime);
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
              const SizedBox(height: 5),
            ],
          ),
        ),
      ],
    );
  }
}
