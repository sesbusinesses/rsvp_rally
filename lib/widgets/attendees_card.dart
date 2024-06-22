import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/rating_indicator.dart';
import 'package:rsvp_rally/widgets/user_card.dart';

class AttendeesCard extends StatelessWidget {
  final double rating;
  final String eventID;

  const AttendeesCard({super.key, required this.eventID, required this.rating});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchEventAttendees(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> attendees = snapshot.data!;
            // Sort attendees by rating
            attendees.sort((a, b) => b['rating'].compareTo(a['rating']));

            return Padding(
              padding: EdgeInsets.only(
                  left: screenSize.width * 0.075,
                  right: screenSize.width * 0.075,
                  bottom: 100),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: screenSize.width * 0.85,
                decoration: BoxDecoration(
                  color: AppColors.light, // Dark background color
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: getInterpolatedColor(rating),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendees',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    ...attendees.map((attendee) {
                      IconData iconData =
                          Icons.question_mark; // Default to maybe
                      switch (attendee['isComing']) {
                        case 'yes':
                          iconData = Icons.check;
                          break;
                        case 'no':
                          iconData = Icons.close;
                          break;
                        case 'maybe':
                        default:
                          iconData = Icons.question_mark;
                          break;
                      }
                      return Column(children: [
                        UserCard(
                          username: attendee['username'],
                          icon: Icon(iconData,
                              color: getInterpolatedColor(attendee['rating'])),
                        ),
                      ]);
                    }),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16)),
            );
          }
        }
        return Container();
      },
    );
  }
}
