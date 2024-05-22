import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/user_card.dart';

class AttendeeEntrySection extends StatefulWidget {
  final String username;

  const AttendeeEntrySection({
    super.key,
    required this.username,
  });

  @override
  AttendeeEntrySectionState createState() => AttendeeEntrySectionState();
}

class AttendeeEntrySectionState extends State<AttendeeEntrySection> {
  List<String> friendsList = [];
  Map<String, bool> selectedFriends = {};

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(widget.username).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> friends = userData['Friends'] ?? [];
      setState(() {
        friendsList = List<String>.from(friends);
        for (var friend in friendsList) {
          selectedFriends[friend] = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: screenSize.width * 0.85,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Select Friends to Invite',
                  style: TextStyle(
                    fontSize: 20,
                  )),
            ),
            Column(
              children: friendsList
                  .map((friend) => CheckboxListTile(
                        title: UserCard(
                          username: friend,
                          showUsername: false,
                        ),
                        value: selectedFriends[friend],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedFriends[friend] = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity
                            .leading, // positions the checkbox at the beginning of the tile
                      ))
                  .toList(),
            ),
          ],
        ));
  }
}
