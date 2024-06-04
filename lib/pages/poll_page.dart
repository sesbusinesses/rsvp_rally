import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/poll_card.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';

class PollPage extends StatefulWidget {
  final String eventID;
  final String username;

  const PollPage({super.key, required this.eventID, required this.username});

  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  double userRating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserRating();
  }

  Future<void> fetchUserRating() async {
    double? rating = await getUserRating(widget.username);
    setState(() {
      userRating = rating ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Poll'),
        backgroundColor: Colors.transparent, // Transparent background for AppBar
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.light,
              getInterpolatedColor(userRating), // Use the interpolated color
            ], // Light to dynamic color gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Events')
              .doc(widget.eventID)
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
                      userRating: userRating,
                      eventID: widget.eventID,
                      username: widget.username,
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
      bottomNavigationBar: BottomNav(
        eventID: widget.eventID,
        username: widget.username,
        selectedIndex: 1, // Index for PollPage
      ),
    );
  }
}

