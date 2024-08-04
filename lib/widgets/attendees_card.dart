import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/user_card.dart';

class AttendeesCard extends StatelessWidget {
  final double rating;
  final String eventID;
  final String username;

  const AttendeesCard(
      {super.key,
      required this.eventID,
      required this.rating,
      required this.username});

  Future<List<Map<String, dynamic>>> fetchEventAttendees(String eventID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(eventID).get();
    List<Map<String, dynamic>> attendeesDetails = [];

    if (eventDoc.exists) {
      var eventData = eventDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> attendeesMap = eventData['Attendees'] ?? {};
      String hostUsername = eventData['HostName'];

      // Ensure host is included if not already present
      if (!attendeesMap.containsKey(hostUsername)) {
        attendeesMap[hostUsername] = 'yes';
      }

      // Fetch user documents in parallel
      List<Future<DocumentSnapshot>> userDocsFutures = attendeesMap.keys
          .map((username) => firestore.collection('Users').doc(username).get())
          .toList();

      List<DocumentSnapshot> userDocs = await Future.wait(userDocsFutures);

      for (DocumentSnapshot userDoc in userDocs) {
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String username = userDoc.id;
          String comingStatus = attendeesMap[username] ?? 'maybe';
          attendeesDetails.add({
            'username': username,
            'firstName': userData['FirstName'],
            'lastName': userData['LastName'],
            'rating': userData['Rating'],
            'isComing': comingStatus // Include coming status
          });
        }
      }
    }
    return attendeesDetails;
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchEventAttendees(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> attendees = snapshot.data!;
            // Filter and sort attendees by rating
            List<Map<String, dynamic>> comingAttendees = attendees
                .where((attendee) => attendee['isComing'] == 'yes')
                .toList();
            attendees.sort((a, b) => b['rating'].compareTo(a['rating']));

            return Padding(
              padding: EdgeInsets.only(
                  left: screenSize.width * 0.075,
                  right: screenSize.width * 0.075,
                  bottom: 10),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text('Attendees', style: AppColors.titleStyle),
                      Expanded(child: Container()),
                      Icon(Icons.people, color: getInterpolatedColor(rating)),
                      const SizedBox(width: 5),
                      Text(comingAttendees.length.toString(),
                          style: TextStyle(
                              fontSize: 20,
                              color: getInterpolatedColor(rating)))
                    ]),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attendees.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> attendee = attendees[index];
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
                          return UserCard(
                            username: attendee['username'],
                            icon: Icon(iconData,
                                color:
                                    getInterpolatedColor(attendee['rating'])),
                            viewerUsername: username,
                            isClickable: true,
                            isShop: true,
                          );
                        },
                      ),
                    ),
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
