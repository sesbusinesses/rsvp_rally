import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/details_page.dart';

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
    }
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
    Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsPage(
                username: widget.username,
                userRating: widget.userRating,
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
            padding: const EdgeInsets.all(15),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark, // Light text color
                        ),
                      ),
                      Text(
                        eventDate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              AppColors.accentDark, // Medium light text color
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: getInterpolatedColor(widget.userRating)),
                ]),
          ),
        ),
      ),
    );
  }
}
