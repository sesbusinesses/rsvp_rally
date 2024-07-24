import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/create_event_button.dart';
import 'package:rsvp_rally/widgets/eventcard.dart';
import 'package:rsvp_rally/widgets/user_rating_indicator.dart';
import 'package:rsvp_rally/models/location_service.dart';

class EventPage extends StatefulWidget {
  final String username;
  final double userRating;

  const EventPage(
      {required this.username, required this.userRating, super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage>
    with SingleTickerProviderStateMixin {
  late Future<List<String>> userEventsFuture;
  List<String> existingEventIds = [];
  Map<String, DateTime?> eventStartTimes = {};
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    userEventsFuture = Future.value([]);
    loadData();
    requestPermission(context);
    enableLocationTracking(widget.username, context);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final eventIds = await getUserEvents(widget.username);
      await checkEventsExistenceAndRSVP(eventIds);

      if (mounted) {
        setState(() {
          userEventsFuture = Future.value(existingEventIds);
          isLoading = false;
        });
      }
    } catch (e) {
      log("Error in loadData: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<String>> getUserEvents(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<String> eventIds = [];

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();

      if (!userDoc.exists) {
        log("No user found with username $username");
        return eventIds;
      }

      eventIds = List.from(userDoc.get('Events'));
      return eventIds;
    } catch (e) {
      log("Error fetching user events: $e");
      return eventIds;
    }
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
        bool hasRespondedNo = true; // Assume 'No' until proven otherwise

        for (var pollName in polls.keys) {
          if (pollName.startsWith('RSVP for')) {
            var responses = polls[pollName];
            if (responses['Yes'] != null &&
                responses['Yes'].contains(username)) {
              hasRespondedYes = true;
              hasRespondedNo =
                  false; // User has responded 'Yes', so not all 'No'
              break; // No need to check further if 'Yes' is found
            }
            if (responses['No'] != null && responses['No'].contains(username)) {
              // Continue checking other polls
            } else {
              hasRespondedNo =
                  false; // User has not responded 'No' to this poll
            }
          }
        }

        if (hasRespondedYes) return 'yes';
        if (hasRespondedNo)
          return 'no'; // Return 'no' if no 'Yes' was found and at least one 'No' was found
        return 'maybe'; // Default response if no 'Yes' and no 'No' was found
      } else {
        return 'maybe'; // Default response if the event does not exist
      }
    } catch (e) {
      log("Error fetching event or processing data: $e");
      return 'maybe'; // Default response in case of error
    }
  }

  Future<void> checkEventsExistenceAndRSVP(List<String> eventIds) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<String> tempEventIds = [];
    Map<String, DateTime?> tempEventStartTimes = {};

    try {
      List<Future<void>> futures = eventIds.map((eventId) async {
        DocumentSnapshot eventDoc =
            await firestore.collection('Events').doc(eventId).get();
        if (eventDoc.exists) {
          String rsvpStatus = await isComing(eventId, widget.username);
          if (rsvpStatus != 'no') {
            tempEventIds.add(eventId);
            DateTime? startTime = await getEventStartTime(eventId);
            tempEventStartTimes[eventId] = startTime;
          } else {
            await _removeEventFromUserDoc(
                widget.username, eventId, eventDoc['EventName'], false);
          }
        } else {
          await _removeEventFromUserDoc(
              widget.username, eventId, "Unknown Event", true);
        }
      }).toList();

      await Future.wait(futures);

      tempEventIds.sort((a, b) {
        DateTime? startTimeA = tempEventStartTimes[a];
        DateTime? startTimeB = tempEventStartTimes[b];
        if (startTimeA == null && startTimeB == null) return 0;
        if (startTimeA == null) return 1;
        if (startTimeB == null) return -1;
        return startTimeA.compareTo(startTimeB);
      });

      existingEventIds = tempEventIds;
      eventStartTimes = tempEventStartTimes;
    } catch (e) {
      log("Error in checkEventsExistenceAndRSVP: $e");
    }
  }

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

    return timelineData;
  }

  Future<DateTime?> getEventStartTime(String eventID) async {
    List<Map<String, dynamic>> timelineData = await fetchTimeline(eventID);
    DateTime? startTime;

    for (var phase in timelineData) {
      var phaseStartTime = phase['startTime'] as DateTime?;
      if (phaseStartTime != null) {
        if (startTime == null || phaseStartTime.isBefore(startTime)) {
          startTime = phaseStartTime;
        }
      }
    }
    return startTime;
  }

  Future<void> _removeEventFromUserDoc(String username, String eventID,
      String eventName, bool eventExpired) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDocRef = firestore.collection('Users').doc(username);
    DocumentReference eventDocRef = firestore.collection('Events').doc(eventID);

    WriteBatch batch = firestore.batch();

    try {
      DocumentSnapshot userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        log("No user found with username $username");
        return;
      }

      List<String> events = List.from(userDoc.get('Events'));
      if (events.contains(eventID)) {
        events.remove(eventID);
        batch.update(userDocRef, {'Events': events});

        if (eventExpired) {
          DocumentReference eventChatRef =
              firestore.collection('Chats').doc(eventID);
          batch.delete(eventChatRef);
        } else {
          DocumentSnapshot eventDoc = await eventDocRef.get();
          if (eventDoc.exists) {
            List<String> declined;
            if ((eventDoc.data() as Map).containsKey('Declined')) {
              declined = List.from(eventDoc.get('Declined'));
            } else {
              declined = [];
            }

            List<String> attendees = List.from(eventDoc.get('Attendees'));
            if (attendees.contains(username)) {
              attendees.remove(username);
              batch.update(eventDocRef, {'Attendees': attendees});
            }

            if (!declined.contains(username)) {
              declined.add(username);
              batch.update(eventDocRef, {'Declined': declined});
            }
          }
        }

        await batch.commit();
      } else {
        log("Event $eventID not found in user $username's events list");
      }
    } catch (e) {
      log("Error in _removeEventFromUserDoc: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double userRating = widget.userRating;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: UserRatingIndicator(userRating: userRating),
              ),
              isLoading
                  ? const CupertinoActivityIndicator(radius: 15)
                  : Expanded(
                      child: FutureBuilder<List<String>>(
                        future: userEventsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CupertinoActivityIndicator(radius: 15);
                          } else if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'Error fetching events. Please try again later.',
                                style: AppColors.bodyStyle,
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'You don\'t have any events yet. Click the button below to create one! Or add some friends and get invited to their events!',
                                style: AppColors.bodyStyle,
                              ),
                            );
                          } else {
                            List<String> eventIds = snapshot.data!;
                            return FutureBuilder<void>(
                              future: checkEventsExistenceAndRSVP(eventIds),
                              builder: (context, checkSnapshot) {
                                if (checkSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CupertinoActivityIndicator(
                                      radius: 15);
                                } else {
                                  if (existingEventIds.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Text(
                                        'You don\'t have any events yet. Click the button below to create one! Or add some friends and get invited to their events!',
                                        style: AppColors.bodyStyle,
                                      ),
                                    );
                                  } else {
                                    return SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children:
                                            existingEventIds.map((eventId) {
                                          return EventCard(
                                            eventID: eventId,
                                            userRating: userRating,
                                            username: widget.username,
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          CreateEventButton(username: widget.username, userRating: userRating),
    );
  }
}
