import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/event_page_view.dart';
import 'package:rsvp_rally/widgets/event_image_display.dart';

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
  bool eventExists = true;

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
      if (mounted) {
        setState(() {
          eventName = data['EventName'] ?? "Event Name Not Found";
          Timestamp startTime = data['Timeline'][0]['StartTime'];
          DateTime date = startTime.toDate();
          eventDate = "${_monthToString(date.month)} ${date.day}";
        });
      }
    } else {
      log("Event not found");
      // Remove the event reference from the user's document
      await _removeEventFromUserDoc(widget.username, widget.eventID);
      if (mounted) {
        setState(() {
          eventExists = false; // Mark the event as non-existent
        });
      }
    }
  }

  Future<void> _removeEventFromUserDoc(String username, String eventID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDocRef = firestore.collection('Users').doc(username);

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userDocRef);

      if (!userDoc.exists) {
        log("No user found with username $username");
        return;
      }

      List<String> events = List.from(userDoc.get('Events'));
      if (events.contains(eventID)) {
        events.remove(eventID);
        transaction.update(userDocRef, {'Events': events});
        log("Removed event $eventID from user $username");
      }
    });
  }

  String _monthToString(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (!eventExists) {
      return Container(); // Return an empty container if the event doesn't exist
    }

    Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventPageView(
                username: widget.username,
                rating: widget.userRating,
                eventID: widget.eventID,
              ),
            ),
          );
        },
        child: Container(
          width: screenSize.width * 0.85,
          height: 100, // Increased height for better aesthetics
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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                EventImageDisplay(
                    eventID: widget.eventID,
                    rating: widget.userRating,
                    clickable: false), // New widget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: screenSize.width * 0.4 + 10,
                      child: Text(
                        eventName,
                        style: AppColors.titleStyle, // Light text color
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      eventDate,
                      style: AppColors.lightDateStyle,
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: getInterpolatedColor(widget.userRating),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
