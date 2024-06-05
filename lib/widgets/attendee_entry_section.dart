import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

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
  List<Map<String, dynamic>> filteredFriends = [];
  Map<String, bool> selectedFriends = {};
  TextEditingController searchController = TextEditingController();

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
              'firstName': friendData['FirstName'] ?? "",
              'lastName': friendData['LastName'] ?? "",
              'rating': rating,
            });
          } else {
            log('Friend document does not exist: $friendUsername');
          }
        }

        friendsWithRatings.sort((a, b) => b['rating'].compareTo(a['rating']));

        setState(() {
          friendsData = friendsWithRatings;
          filteredFriends = friendsData;
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

  void filterFriends(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFriends = friendsData;
      });
    } else {
      String lowerCaseQuery = query.toLowerCase();

      List<Map<String, dynamic>> temp = [];

      if (query.length == 1) {
        temp = friendsData.where((friend) {
          return friend['username'].toLowerCase().startsWith(lowerCaseQuery) ||
              friend['firstName'].toLowerCase().startsWith(lowerCaseQuery);
        }).toList();
      } else {
        temp = friendsData.where((friend) {
          return friend['username'].toLowerCase().contains(lowerCaseQuery) ||
              friend['firstName'].toLowerCase().contains(lowerCaseQuery) ||
              friend['lastName'].toLowerCase().contains(lowerCaseQuery);
        }).toList();
      }

      temp.sort((a, b) {
        bool aIsExactMatch = a['username'].toLowerCase() == lowerCaseQuery ||
            a['firstName'].toLowerCase() == lowerCaseQuery ||
            a['lastName'].toLowerCase() == lowerCaseQuery;
        bool bIsExactMatch = b['username'].toLowerCase() == lowerCaseQuery ||
            b['firstName'].toLowerCase() == lowerCaseQuery ||
            b['lastName'].toLowerCase() == lowerCaseQuery;

        if (aIsExactMatch && !bIsExactMatch) return -1;
        if (!aIsExactMatch && bIsExactMatch) return 1;

        int usernameCompare =
            a['username'].toLowerCase().compareTo(b['username'].toLowerCase());
        if (usernameCompare != 0) return usernameCompare;

        int firstNameCompare = a['firstName']
            .toLowerCase()
            .compareTo(b['firstName'].toLowerCase());
        if (firstNameCompare != 0) return firstNameCompare;

        return a['lastName']
            .toLowerCase()
            .compareTo(b['lastName'].toLowerCase());
      });

      setState(() {
        filteredFriends = temp;
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
            WideTextBox(
              hintText: 'Search through your friends...',
              controller: searchController,
              onChanged: (value) => filterFriends(value),
            ),
            Column(
              children: filteredFriends
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
