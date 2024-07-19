import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

import 'package:rsvp_rally/models/colors.dart';

Future<List<Map<String, dynamic>>> fetchTimeline(String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> timelineData = [];

  try {
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(eventID).get();

    if (eventDoc.exists) {
      var eventData = eventDoc.data() as Map<String, dynamic>;
      var timeline = eventData['Timeline'] as List<dynamic>;

      for (var phase in timeline) {
        Map<String, dynamic> phaseData = {
          'startTime': (phase['StartTime'] as Timestamp).toDate(),
          'phaseName': phase['PhaseName'],
          'phaseLocation': phase['PhaseLocation'],
          'endTime': phase.containsKey('EndTime')
              ? (phase['EndTime'] as Timestamp).toDate()
              : null
        };
        timelineData.add(phaseData);
      }
    }
  } catch (e) {
    log("Error fetching timeline: $e");
  }
  // log("Fetched timeline data: $timelineData");

  return timelineData;
}

class EventTimeDisplay extends StatelessWidget {
  final String eventID;
  final double rating;

  const EventTimeDisplay(
      {super.key, required this.eventID, required this.rating});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTimeline(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No timeline data available');
        } else {
          List<Widget> timelineWidgets = [];

          // Consolidate consecutive time ranges
          DateTime? consolidatedStartTime;
          DateTime? consolidatedEndTime;
          String startDateStr = '';
          String endDateStr = '';
          for (var phase in snapshot.data!) {
            var startTime = phase['startTime'] as DateTime;
            var endTime = phase['endTime'] as DateTime;

            if (consolidatedStartTime == null) {
              consolidatedStartTime = startTime;
              startDateStr = DateFormat('MMMM d').format(startTime);
            }
            consolidatedEndTime = endTime;
            endDateStr = DateFormat('MMMM d').format(endTime);
          }

          if (consolidatedStartTime != null && consolidatedEndTime != null) {
            String startTimeStr =
                DateFormat('h:mm a').format(consolidatedStartTime);
            String endTimeStr =
                DateFormat('h:mm a').format(consolidatedEndTime);

            if (startDateStr == endDateStr) {
              timelineWidgets.add(Expanded(
                  child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                    '${startDateStr.substring(0, 3)} ${startDateStr.substring(startDateStr.length - 2).trim()}',
                    style: AppColors.eventTimeDisplayStyle
                        .copyWith(color: getTextOnRatingColor(rating))),
              )));
            } else {
              timelineWidgets.add(Expanded(
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '${startDateStr.substring(0, 3)} ${startDateStr.substring(startDateStr.length - 2).trim()}',
                        style: AppColors.eventTimeDisplayStyle
                            .copyWith(color: getTextOnRatingColor(rating)),
                      ))));
              timelineWidgets.add(Expanded(
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '-',
                        style: AppColors.eventTimeDisplayStyle
                            .copyWith(color: getTextOnRatingColor(rating)),
                      ))));
              timelineWidgets.add(Expanded(
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '${endDateStr.substring(0, 3)} ${endDateStr.substring(endDateStr.length - 2).trim()}',
                        style: AppColors.eventTimeDisplayStyle
                            .copyWith(color: getTextOnRatingColor(rating)),
                      ))));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: timelineWidgets,
          );
        }
      },
    );
  }
}
