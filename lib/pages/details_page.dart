import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/event_timeline.dart';
import 'package:rsvp_rally/widgets/details_card.dart';
import 'package:rsvp_rally/widgets/attendees_card.dart';

class DetailsPage extends StatefulWidget {
  final String eventID;

  const DetailsPage({super.key, required this.eventID});

  @override
  DetailsPageState createState() => DetailsPageState();
}

class DetailsPageState extends State<DetailsPage> {
  String eventName = 'Event Details'; // Default text

  @override
  void initState() {
    super.initState();
    fetchEventName();
  }

  Future<void> fetchEventName() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(widget.eventID).get();

    if (eventDoc.exists) {
      Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        eventName = data['EventName'] ??
            'Event Details'; // Set the event name or default
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventName), // Dynamically set the title
      ),
      body: CustomScrollView(
        slivers: [
          EventTimeline(eventID: widget.eventID),
          SliverToBoxAdapter(child: DetailsCard(eventID: widget.eventID)),
          SliverToBoxAdapter(child: AttendeesCard(eventID: widget.eventID)),
        ],
      ),
    );
  }
}
