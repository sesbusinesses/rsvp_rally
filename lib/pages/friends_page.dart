import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/pages/add_friends_page.dart';

class FriendsPage extends StatefulWidget {
  final String username;
  final double rating;

  const FriendsPage({super.key, required this.username, required this.rating});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> friendsData = [];
  List<Map<String, dynamic>> filteredFriends = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(widget.username).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<String> friendsUsernames = List.from(userData['Friends'] ?? []);
        List<Map<String, dynamic>> friends = [];

        for (String friendUsername in friendsUsernames) {
          DocumentSnapshot friendDoc =
              await firestore.collection('Users').doc(friendUsername).get();

          if (friendDoc.exists) {
            Map<String, dynamic> friendData =
                friendDoc.data() as Map<String, dynamic>;
            friends.add({
              'username': friendUsername,
              'rating': double.tryParse(friendData['Rating'].toString()) ?? 0.0,
            });
          }
        }

        friends.sort((a, b) => b['rating'].compareTo(a['rating']));

        setState(() {
          friendsData = friends;
          filteredFriends = friendsData;
        });
      }
    } catch (e) {
      // Handle error
      print("Error fetching friends: $e");
    }
  }

  void filterFriends(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFriends = friendsData;
      });
    } else {
      List<Map<String, dynamic>> temp = [];
      for (Map<String, dynamic> friend in friendsData) {
        if (friend['username'].toLowerCase().contains(query.toLowerCase())) {
          temp.add(friend);
        }
      }
      setState(() {
        filteredFriends = temp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Profile'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: Stack(children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserCard(username: widget.username),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: screenSize.width * 0.85,
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Light background color
                        border: Border.all(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('Your Friends',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: WideTextBox(
                                  hintText: 'Search through your friends...',
                                  controller: searchController,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search_rounded),
                                onPressed: () =>
                                    filterFriends(searchController.text),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...filteredFriends.map((friendData) =>
                              UserCard(username: friendData['username'])),
                          const SizedBox(height: 80)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.075, vertical: 20),
              height: 100,
              child: WideButton(
                buttonText: 'Find More Friends +',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddFriendsPage(username: widget.username),
                    ),
                  );
                },
                rating: widget.rating,
              ),
            ),
          ),
        ]));
  }
}
