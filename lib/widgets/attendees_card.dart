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
      List<dynamic> attendeesUsernames = eventData['Attendees'] ?? [];
      List<dynamic> declinedUsernames = eventData['Declined'] ?? [];
      String hostUsername = eventData['HostName'];

      // Combine attendees and declined lists, and ensure host is included if not already present
      Set<String> allUsernames = Set.from(attendeesUsernames.cast<String>())
        ..addAll(declinedUsernames.cast<String>())
        ..add(hostUsername);

      // Fetch user documents in parallel
      List<Future<DocumentSnapshot>> userDocsFutures = allUsernames
          .map((username) => firestore.collection('Users').doc(username).get())
          .toList();

      List<DocumentSnapshot> userDocs = await Future.wait(userDocsFutures);

      for (DocumentSnapshot userDoc in userDocs) {
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String username = userDoc.id;
          String comingStatus = await isComing(
              eventID, username); // Fetch and include coming status
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

  Future<String> isComing(String eventID, String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot eventDoc =
          await firestore.collection('Events').doc(eventID).get();
      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> polls = eventData['Polls'] ?? {};

        bool hasRespondedYes = false;
        bool hasRespondedNo = false; // Updated logic

        for (var pollName in polls.keys) {
          if (pollName.startsWith('RSVP for')) {
            var responses = polls[pollName];
            if (responses['Yes'] != null &&
                responses['Yes'].contains(username)) {
              hasRespondedYes = true;
            }
            if (responses['No'] != null && responses['No'].contains(username)) {
              hasRespondedNo = true;
            }
          }
        }

        if (hasRespondedYes) return 'yes';
        if (hasRespondedNo) return 'no';
        return 'maybe';
      } else {
        return 'maybe'; // Default response if the event does not exist
      }
    } catch (e) {
      log("Error fetching event or processing data: $e");
      return 'maybe'; // Default response in case of error
    }
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
