import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/eventcard.dart';
import 'package:rsvp_rally/models/database_puller.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  EventPageState createState() => EventPageState();
}

class EventPageState extends State<EventPage> {
  final String username = 'bossman5960';
  List<String> eventIds = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    eventIds = await getUserEvents(username);
    setState(() {});
    print(eventIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Rally'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:
                eventIds.map((eventId) => EventCard(eventID: eventId)).toList(),
          ),
        ),
      ),
    );
  }
}
