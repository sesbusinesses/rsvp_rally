import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/poll_card.dart';

class PollPage extends StatelessWidget {
  final String eventID;
  final String username;

  const PollPage({super.key, required this.eventID, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Poll'),
        backgroundColor:
            Colors.transparent, // Transparent background for AppBar
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFfefdfd),
              Color(0xFF5f42b2)
            ], // White to purple gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Events')
              .doc(eventID)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData && snapshot.data != null) {
                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;
                Map<String, dynamic> polls =
                    Map<String, dynamic>.from(data['Polls']);

                return ListView(
                  children: polls.entries.map((entry) {
                    return PollCard(
                      eventID: eventID,
                      username: username,
                      pollData: {
                        'question': entry.key,
                        'responses': entry.value
                      },
                    );
                  }).toList(),
                );
              } else if (snapshot.hasError) {
                return Center(
                    child: Text("Error fetching data: ${snapshot.error}"));
              } else {
                return const Center(
                    child: Text("No data available for this event."));
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
