import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/event_timeline.dart'; // Import the new EventTimeline widget

class DetailsPage extends StatelessWidget {
  final String eventID;

  const DetailsPage({Key? key, required this.eventID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: EventTimeline(eventID: eventID), // Use the new EventTimeline widget
    );
  }
}
