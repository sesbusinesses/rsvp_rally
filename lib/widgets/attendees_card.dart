import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Ensure this includes fetchEventAttendees

class AttendeesCard extends StatelessWidget {
  final String eventID;

  const AttendeesCard({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchEventAttendees(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Padding(
              padding: EdgeInsets.only(
                  left: screenSize.width * 0.075,
                  right: screenSize.width * 0.075,
                  bottom: 50),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: screenSize.width * 0.85,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendees',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(
                        height:
                            15), // Space between the header and the first attendee
                    ...snapshot.data!.map((attendee) {
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          width: screenSize.width * 0.8,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Color.lerp(Colors.red, Colors.green,
                                        attendee['rating']) ??
                                    Colors.red),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Expanded(child: Text(attendee['username'])),
                              Expanded(
                                  child: Text(
                                      "${attendee['firstName']} ${attendee['lastName']}",
                                      style: TextStyle(
                                          color: Color.lerp(
                                                  Colors.red,
                                                  Colors.green,
                                                  attendee['rating']) ??
                                              Colors.red))),
                              Expanded(
                                  child: Text(
                                      "Rating: ${attendee['rating'].toString()}",
                                      style: TextStyle(
                                          color: Color.lerp(
                                                  Colors.red,
                                                  Colors.green,
                                                  attendee['rating']) ??
                                              Colors.red))),
                              Icon(iconData,
                                  color: Color.lerp(Colors.red, Colors.green,
                                          attendee['rating']) ??
                                      Colors.red),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }
        return const Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
