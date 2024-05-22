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

  const EventCard(
      {super.key,
      required this.eventID,
      required this.userRating,
      required this.username});

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
      print("Event not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          width: screenSize.width * 0.85,
          height: 130,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      eventDate,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  width: screenSize.width * 0.8,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconButton(Icons.document_scanner,
                          DetailsPage(eventID: widget.eventID)),
                      iconButton(
                          Icons.bar_chart, PollPage(eventID: widget.eventID)),
                      iconButton(Icons.chat, ChatPage(eventID: widget.eventID)),
                      iconButton(
                          Icons.edit,
                          EditEventPage(
                              eventID: widget.eventID,
                              username: widget.username)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget iconButton(IconData icon, Widget page) {
    return GestureDetector(
      child: Icon(icon,
          color: Color.lerp(Colors.red, Colors.green, widget.userRating)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
