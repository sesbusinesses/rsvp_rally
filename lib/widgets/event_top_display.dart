import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/event_image_display.dart';
import 'package:rsvp_rally/widgets/event_time_display.dart';

class EventTopDisplay extends StatefulWidget {
  final String eventID;
  final double userRating;

  const EventTopDisplay({
    super.key,
    required this.eventID,
    required this.userRating,
  });

  @override
  EventTimeDsplayState createState() => EventTimeDsplayState();
}

class EventTimeDsplayState extends State<EventTopDisplay> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(15),
        width: screenSize.width * 0.3875,
        height: screenSize.width * 0.3875,
        decoration: BoxDecoration(
          color: AppColors.light, // Dark background color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: getInterpolatedColor(widget.userRating),
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
        child: EventTimeDisplay(eventID: widget.eventID),
      ),
      SizedBox(width: screenSize.width * 0.075),
      Container(
        padding: const EdgeInsets.all(15),
        width: screenSize.width * 0.3875,
        height: screenSize.width * 0.3875,
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: getInterpolatedColor(widget.userRating),
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
        child: EventImageDisplay(
            eventID: widget.eventID, rating: widget.userRating),
      )
    ]);
  }
}
