import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/create_event_button.dart';
import 'package:rsvp_rally/widgets/eventcard.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/user_rating_indicator.dart';
import 'package:rsvp_rally/widgets/view_friends_button.dart';

class EventPage extends StatefulWidget {
  final String username;

  const EventPage({required this.username, super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage> {
  List<String> eventIds = [];
  double userRating = 0;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    eventIds = await getUserEvents(widget.username);
    double? fetchedRating = await getUserRating(widget.username);
    userRating = fetchedRating ?? 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Rally'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          ViewFriendsButton(username: widget.username, userRating: userRating),
        ],
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserRatingIndicator(
                userRating:
                    userRating), // This remains at the top, not scrollable
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: eventIds
                            .map((eventId) => EventCard(
                                eventID: eventId, userRating: userRating))
                            .toList(),
                      ),
                    ),
                  ]),
            ),
          ],
        ),
      )),
      floatingActionButton: CreateEventButton(userRating: userRating),
      //floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
