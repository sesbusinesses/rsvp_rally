import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/create_poll_button.dart';
import 'package:rsvp_rally/widgets/poll_card.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';

class PollPage extends StatefulWidget {
  final double rating;
  final String eventID;
  final String username;

  const PollPage(
      {super.key,
      required this.rating,
      required this.eventID,
      required this.username});

  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    checkIfHost();
  }

  Future<void> checkIfHost() async {
    DocumentSnapshot eventDoc = await FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.eventID)
        .get();

    if (eventDoc.exists) {
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        isHost = eventData['HostName'] == widget.username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Poll'),
        backgroundColor:
            Colors.transparent, // Transparent background for AppBar
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
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

                  // Sort the polls by CloseTime
                  List<MapEntry<String, dynamic>> sortedPolls =
                      polls.entries.toList();
                  sortedPolls.sort((a, b) {
                    Timestamp aCloseTime = a.value['CloseTime'];
                    Timestamp bCloseTime = b.value['CloseTime'];
                    return aCloseTime.compareTo(bCloseTime);
                  });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        bottom: 170), // Padding to avoid overlap
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...sortedPolls.map((entry) {
                              return PollCard(
                                userRating: widget.rating,
                                eventID: widget.eventID,
                                username: widget.username,
                                pollData: {
                                  'question': entry.key,
                                  'responses': entry.value,
                                },
                              );
                            }),
                            const SizedBox(height: 80), // Space at the bottom
                          ],
                        ),
                      ),
                    ),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              rating: widget.rating,
              eventID: widget.eventID,
              username: widget.username,
              selectedIndex: 1, // Index for PollPage
            ),
          ),
        ],
      ),
      floatingActionButton: isHost
          ? Padding(
              padding: const EdgeInsets.only(
                  bottom: 40.0), // Adjust offset as needed
              child: CreatePollButton(
                eventID: widget.eventID,
                userRating: widget.rating,
                username: widget.username,
              ),
            )
          : null,
    );
  }
}
