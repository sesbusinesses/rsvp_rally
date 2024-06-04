import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/user_card.dart';

class AttendeeEntrySection extends StatefulWidget {
  final double rating;
  final String username;

  const AttendeeEntrySection({
    super.key,
    required this.rating,
    required this.username,
  });

  @override
  AttendeeEntrySectionState createState() => AttendeeEntrySectionState();
}

class AttendeeEntrySectionState extends State<AttendeeEntrySection> {
  List<Map<String, dynamic>> friendsData = [];
  Map<String, bool> selectedFriends = {};

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    log('Fetching friends for user: ${widget.username}');
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(widget.username).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> friends = userData['Friends'] ?? [];
        log('Friends list: $friends');

        List<Map<String, dynamic>> friendsWithRatings = [];

        for (String friendUsername in friends) {
          DocumentSnapshot friendDoc =
              await firestore.collection('Users').doc(friendUsername).get();

          if (friendDoc.exists) {
            Map<String, dynamic> friendData =
                friendDoc.data() as Map<String, dynamic>;
            double rating =
                double.tryParse(friendData['Rating'].toString()) ?? 0.0;
            log('Friend: $friendUsername, Rating: $rating');

            friendsWithRatings.add({
              'username': friendUsername,
              'rating': rating,
            });
          } else {
            log('Friend document does not exist: $friendUsername');
          }
        }

        friendsWithRatings.sort((a, b) => b['rating'].compareTo(a['rating']));

        setState(() {
          friendsData = friendsWithRatings;
          for (var friend in friendsData) {
            selectedFriends[friend['username']] = false;
          }
          log('Friends data with ratings: $friendsData');
        });
      } else {
        log('User document does not exist: ${widget.username}');
      }
    } catch (e) {
      log('Error fetching friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: screenSize.width * 0.85,
        decoration: BoxDecoration(
          border: Border.all(color: getInterpolatedColor(widget.rating)),
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
              children: friendsData
                  .map((friend) => CheckboxListTile(
                        title: UserCard(
                          username: friend['username'],
                          showUsername: false,
                        ),
                        value: selectedFriends[friend['username']],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedFriends[friend['username']] = value!;
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
