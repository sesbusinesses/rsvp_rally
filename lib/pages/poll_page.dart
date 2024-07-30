import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/create_poll_button.dart';
import 'package:rsvp_rally/widgets/poll_card.dart';

class PollPage extends StatefulWidget {
  final double rating;
  final String eventID;
  final String username;

  const PollPage({
    super.key,
    required this.rating,
    required this.eventID,
    required this.username,
  });

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

  Future<List<Map<String, dynamic>>> fetchPolls(String subcollection) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.eventID)
        .collection(subcollection)
        .get();
    return snapshot.docs
        .map(
            (doc) => {'id': doc.id, 'data': doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Poll', style: AppColors.topStyle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: Future.wait([
                fetchPolls('EssentialPolls'),
                fetchPolls('NonessentialPolls')
              ]),
              builder: (context,
                  AsyncSnapshot<List<List<Map<String, dynamic>>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data != null) {
                    List<Map<String, dynamic>> essentialPolls =
                        snapshot.data![0];
                    List<Map<String, dynamic>> nonessentialPolls =
                        snapshot.data![1];

                    List<Map<String, dynamic>> sortedPolls = [
                      ...essentialPolls.map((poll) => {
                            'id': poll['id'],
                            'data': poll['data'],
                            'isEssential': true
                          }),
                      ...nonessentialPolls.map((poll) => {
                            'id': poll['id'],
                            'data': poll['data'],
                            'isEssential': false
                          })
                    ];
                    sortedPolls.sort((a, b) {
                      Timestamp aCloseTime = a['data']['CloseTime'];
                      Timestamp bCloseTime = b['data']['CloseTime'];
                      return aCloseTime.compareTo(bCloseTime);
                    });

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 170),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ...sortedPolls.map((poll) {
                                return PollCard(
                                  userRating: widget.rating,
                                  eventID: widget.eventID,
                                  username: widget.username,
                                  pollID: poll['id'],
                                  pollData: poll['data'],
                                  isEssential: poll['isEssential'],
                                  isHost: isHost,
                                );
                              }),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error fetching data: ${snapshot.error}",
                            style: AppColors.bodyStyle));
                  } else {
                    return Center(
                        child: Text("No data available for this event.",
                            style: AppColors.bodyStyle));
                  }
                }
                return const Center(
                    child: CupertinoActivityIndicator(radius: 15));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isHost
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
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
