import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/event_timeline.dart';
import 'package:rsvp_rally/widgets/details_card.dart';
import 'package:rsvp_rally/widgets/attendees_card.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';

class DetailsPage extends StatefulWidget {
  final String username;
  final String eventID;
  final double userRating;

  const DetailsPage({
    super.key,
    required this.eventID,
    required this.userRating,
    required this.username,
  });

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
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              EventTimeline(eventID: widget.eventID, rating: widget.userRating),
              SliverToBoxAdapter(
                child: DetailsCard(
                    eventID: widget.eventID, rating: widget.userRating),
              ),
              SliverToBoxAdapter(
                child: AttendeesCard(
                    eventID: widget.eventID, rating: widget.userRating),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: BottomNav(
              rating: widget.userRating,
              eventID: widget.eventID,
              username: widget.username,
              selectedIndex: 0, // Index for DetailsPage
            ),
          ),
        ],
      ),
    );
  }
}
