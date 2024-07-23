import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_create_poll_button.dart';
import 'package:rsvp_rally/widgets/group_poll_card.dart';

class GroupPollsPage extends StatefulWidget {
  final String groupID;
  final String username;
  final double userRating;

  const GroupPollsPage({
    super.key,
    required this.groupID,
    required this.username,
    required this.userRating,
  });

  @override
  _GroupPollsPageState createState() => _GroupPollsPageState();
}

class _GroupPollsPageState extends State<GroupPollsPage> {
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    checkIfHost();
  }

  Future<void> checkIfHost() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupID)
        .get();

    if (groupDoc.exists) {
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      setState(() {
        isHost = groupData['Host'] == widget.username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Polls', style: AppColors.topStyle),
        backgroundColor:
            Colors.transparent, // Transparent background for AppBar
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Groups')
                  .doc(widget.groupID)
                  .collection('Polls')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data != null) {
                    List<QueryDocumentSnapshot> pollDocs = snapshot.data!.docs;

                    if (pollDocs.isEmpty) {
                      return Center(
                          child: Text("No polls available for this group.",
                              style: AppColors.bodyStyle));
                    }

                    // Sort the polls by CloseTime
                    pollDocs.sort((a, b) {
                      Timestamp aCloseTime = a['CloseTime'];
                      Timestamp bCloseTime = b['CloseTime'];
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
                              ...pollDocs.map((doc) {
                                Map<String, dynamic> pollData =
                                    doc.data() as Map<String, dynamic>;
                                pollData.remove(
                                    'CloseTime'); // Remove CloseTime from poll options
                                return GroupPollCard(
                                  groupID: widget.groupID,
                                  username: widget.username,
                                  userRating: widget.userRating,
                                  pollData: {
                                    'question': doc.id,
                                    'responses': pollData,
                                    'CloseTime': doc['CloseTime']
                                  },
                                  isHost: isHost,
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
                        child: Text("Error fetching data: ${snapshot.error}",
                            style: AppColors.bodyStyle));
                  } else {
                    return Center(
                        child: Text("No data available for this group.",
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
              padding: const EdgeInsets.only(
                  bottom: 40.0), // Adjust offset as needed
              child: GroupCreatePollButton(
                groupID: widget.groupID,
                username: widget.username,
                userRating: widget.userRating,
              ),
            )
          : null,
    );
  }
}
