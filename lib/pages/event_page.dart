import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/route_observer.dart';
import 'package:rsvp_rally/widgets/create_event_button.dart';
import 'package:rsvp_rally/widgets/eventcard.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/user_rating_indicator.dart';
import 'package:rsvp_rally/widgets/view_friends_button.dart';
import 'package:rsvp_rally/widgets/view_inbox_button.dart';

class EventPage extends StatefulWidget {
  final String username;

  const EventPage({required this.username, super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage> with RouteAware {
  late Future<double?> userRatingFuture;
  late Future<List<String>> userEventsFuture;
  List<String> existingEventIds = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    userRatingFuture = getUserRating(widget.username);
    userEventsFuture = getUserEvents(widget.username);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to RouteObserver
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // Unsubscribe from RouteObserver
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload the data when coming back to this page
    setState(() {
      loadData();
    });
  }

  Future<void> checkEventsExistenceAndRSVP(List<String> eventIds) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    existingEventIds.clear(); // Clear existingEventIds to avoid duplication
    for (String eventId in eventIds) {
      DocumentSnapshot eventDoc =
          await firestore.collection('Events').doc(eventId).get();
      if (eventDoc.exists) {
        String rsvpStatus = await isComing(eventId, widget.username);
        if (rsvpStatus != 'no') {
          existingEventIds.add(eventId);
        } else {
          await _removeEventFromUserDoc(
              widget.username, eventId, eventDoc['EventName'], false);
        }
      } else {
        await _removeEventFromUserDoc(
            widget.username, eventId, eventDoc['EventName'], true);
      }
    }
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
          Timestamp timestamp = Timestamp.now();
          String messageText = '$eventName has passed';
          Map<String, dynamic> message = {
            'text': messageText,
            'type': 'event cancelled',
            'eventID': eventID,
            'timestamp': timestamp,
            'NewMessages': true
          };
          batch.update(userDocRef, {
            'Messages': FieldValue.arrayUnion([message]),
            'NewMessages': true
          });
        }

        print("Removed event $eventID from user $username");

        if (!eventExpired) {
          DocumentSnapshot eventDoc = await eventDocRef.get();
          if (eventDoc.exists) {
            List<String> declined;
            if ((eventDoc.data() as Map).containsKey('Declined')) {
              declined = List.from(eventDoc.get('Declined'));
            } else {
              declined = [];
            }

            if (!declined.contains(username)) {
              declined.add(username);
              batch.update(eventDocRef, {'Declined': declined});
              print("Added $username to Declined list for event $eventID");
            }
          }
        }
      }

      await batch.commit();
      print(
          "Batch commit successful for removing event $eventID from user $username");
    } catch (e) {
      print("Error in _removeEventFromUserDoc: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RSVP Rally',
          style: AppColors.topStyle,
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: FutureBuilder<double?>(
          future: userRatingFuture,
          builder: (context, snapshot) {
            double userRating = snapshot.data ?? 0;
            return ViewInboxButton(
              username: widget.username,
              userRating: userRating,
            );
          },
        ),
        actions: <Widget>[
          FutureBuilder<double?>(
            future: userRatingFuture,
            builder: (context, snapshot) {
              double userRating = snapshot.data ?? 0;
              return ViewFriendsButton(
                username: widget.username,
                userRating: userRating,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: FutureBuilder<List<String>>(
            future: userEventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    FutureBuilder<double?>(
                      future: userRatingFuture,
                      builder: (context, ratingSnapshot) {
                        double userRating = ratingSnapshot.data ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: UserRatingIndicator(userRating: userRating),
                        );
                      },
                    ),
                    const CupertinoActivityIndicator(radius: 15),
                  ],
                );
              } else if (snapshot.hasError) {
                return Column(
                  children: [
                    FutureBuilder<double?>(
                      future: userRatingFuture,
                      builder: (context, ratingSnapshot) {
                        double userRating = ratingSnapshot.data ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: UserRatingIndicator(userRating: userRating),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Error fetching events. Please try again later.',
                        style: AppColors.bodyStyle,
                      ),
                    ),
                  ],
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Column(
                  children: [
                    FutureBuilder<double?>(
                      future: userRatingFuture,
                      builder: (context, ratingSnapshot) {
                        double userRating = ratingSnapshot.data ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: UserRatingIndicator(userRating: userRating),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'You don\'t have any events yet. Click the button below to create one! Or add some friends and get invited to their events!',
                        style: AppColors.bodyStyle,
                      ),
                    ),
                  ],
                );
              } else {
                List<String> eventIds = snapshot.data!;
                return FutureBuilder<void>(
                  future: checkEventsExistenceAndRSVP(eventIds),
                  builder: (context, checkSnapshot) {
                    if (checkSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Column(
                        children: [
                          FutureBuilder<double?>(
                            future: userRatingFuture,
                            builder: (context, ratingSnapshot) {
                              double userRating = ratingSnapshot.data ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child:
                                    UserRatingIndicator(userRating: userRating),
                              );
                            },
                          ),
                          const CupertinoActivityIndicator(radius: 15),
                        ],
                      );
                    } else {
                      if (existingEventIds.isEmpty) {
                        return Column(
                          children: [
                            FutureBuilder<double?>(
                              future: userRatingFuture,
                              builder: (context, ratingSnapshot) {
                                double userRating = ratingSnapshot.data ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: UserRatingIndicator(
                                      userRating: userRating),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'You don\'t have any events yet. Click the button below to create one! Or add some friends and get invited to their events!',
                                style: AppColors.bodyStyle,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            FutureBuilder<double?>(
                              future: userRatingFuture,
                              builder: (context, ratingSnapshot) {
                                double userRating = ratingSnapshot.data ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: UserRatingIndicator(
                                      userRating: userRating),
                                );
                              },
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: existingEventIds.map((eventId) {
                                    return FutureBuilder<double?>(
                                      future: userRatingFuture,
                                      builder: (context, ratingSnapshot) {
                                        double userRating =
                                            ratingSnapshot.data ?? 0;
                                        return EventCard(
                                          eventID: eventId,
                                          userRating: userRating,
                                          username: widget.username,
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    }
                  },
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<double?>(
        future: userRatingFuture,
        builder: (context, snapshot) {
          double userRating = snapshot.data ?? 0;
          return CreateEventButton(
            userRating: userRating,
            username: widget.username,
          );
        },
      ),
    );
  }
}
