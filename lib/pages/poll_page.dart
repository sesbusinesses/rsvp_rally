import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/poll_card.dart';

class PollPage extends StatelessWidget {
  final String eventID;

  const PollPage({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Poll'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('Events').doc(eventID).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data != null) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              Map<String, dynamic> polls =
                  data['Polls'] as Map<String, dynamic>;
              return ListView(
                children: polls.entries.map((entry) {
                  return PollCard(eventID: eventID, pollData: {
                    'question': entry.key,
                    'responses': entry.value
                  });
                }).toList(),
              );
            } else {
              return const Text("No data available for this event.");
            }
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
