import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/edit_event_page.dart';
import 'package:rsvp_rally/pages/chat_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';

class EventCard extends StatefulWidget {
  final String eventID;
  final double userRating;
  final String username;

  const EventCard({
    super.key,
    required this.eventID,
    required this.userRating,
    required this.username,
  });

  @override
  EventCardState createState() => EventCardState();
}

class EventCardState extends State<EventCard> {
  String eventName = "";
  String eventDate = "";

  @override
  void initState() {
    super.initState();
    fetchEventData();
  }

  Future<void> fetchEventData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(widget.eventID).get();

    if (eventDoc.exists) {
      Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        eventName = data['EventName'] ?? "Event Name Not Found";
        Timestamp startTime = data['Timeline'][0]['StartTime'];
        eventDate = "${startTime.toDate().month}/${startTime.toDate().day}";
      });
    } else {
      log("Event not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: screenSize.width * 0.85,
        height: 150, // Increased height for better aesthetics
        decoration: BoxDecoration(
          color: const Color(0xFF010101), // Dark background color
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfefdfd), // Light text color
                    ),
                  ),
                  Text(
                    eventDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFb1aebb), // Medium light text color
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3a3153), // Button container color
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    iconButton(Icons.document_scanner, DetailsPage(eventID: widget.eventID)),
                    iconButton(Icons.bar_chart, PollPage(eventID: widget.eventID)),
                    iconButton(Icons.chat, ChatPage(eventID: widget.eventID)),
                    iconButton(Icons.edit, EditEventPage(eventID: widget.eventID, username: widget.username)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconButton(IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF5f42b2), // Button background color
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFFfefdfd), // Icon color
        ),
      ),
    );
  }
}
