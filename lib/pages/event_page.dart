import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class EventPageState extends State<EventPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Rally'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: FutureBuilder<double?>(
          future: getUserRating(widget.username),
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
            future: getUserRating(widget.username),
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
            future: getUserEvents(widget.username),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CupertinoActivityIndicator();
              } else if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Error fetching events. Please try again later.',
                    style: TextStyle(fontSize: 20),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'You don\'t have any events yet. Click the button below to create one! Or add some friends and get invited to their events!',
                    style: TextStyle(fontSize: 20),
                  ),
                );
              } else {
                List<String> eventIds = snapshot.data!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder<double?>(
                      future: getUserRating(widget.username),
                      builder: (context, ratingSnapshot) {
                        double userRating = ratingSnapshot.data ?? 0;
                        return UserRatingIndicator(userRating: userRating);
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...eventIds.map((eventId) {
                              return FutureBuilder<double?>(
                                future: getUserRating(widget.username),
                                builder: (context, ratingSnapshot) {
                                  double userRating = ratingSnapshot.data ?? 0;
                                  return EventCard(
                                    eventID: eventId,
                                    userRating: userRating,
                                    username: widget.username,
                                  );
                                },
                              );
                            }),
                            const SizedBox(height: 20)
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<double?>(
        future: getUserRating(widget.username),
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
