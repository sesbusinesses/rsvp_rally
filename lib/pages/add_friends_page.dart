// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class AddFriendsPage extends StatefulWidget {
  final String username;

  const AddFriendsPage({super.key, required this.username});

  @override
  AddFriendsPageState createState() => AddFriendsPageState();
}

class AddFriendsPageState extends State<AddFriendsPage> {
  List<String> allUsernames = [];
  List<String> searchResults = [];
  List<String> friendsUsernames = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllUsernames();
    fetchFriends();
  }

  Future<void> fetchAllUsernames() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('Users').get();

    setState(() {
      allUsernames = querySnapshot.docs
          .map((doc) => doc.id)
          .where(
              (username) => username != widget.username) // Exclude own username
          .toList();
    });
  }

  Future<void> fetchFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(widget.username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        friendsUsernames = List.from(userData['Friends'] ?? []);
      });
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
    } else {
      setState(() {
        searchResults = allUsernames
            .where((username) =>
                username.toLowerCase().startsWith(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> addFriend(String friendUsername) async {
    if (!friendsUsernames.contains(friendUsername)) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Add the current user to the friend's request list if not already present
      DocumentSnapshot friendDoc =
          await firestore.collection('Users').doc(friendUsername).get();
      if (friendDoc.exists) {
        List<dynamic> friendRequestsList = friendDoc['Requests'] ?? [];
        if (!friendRequestsList.contains(widget.username)) {
          friendRequestsList.add(widget.username);
          await firestore.collection('Users').doc(friendUsername).update({
            'Requests': friendRequestsList,
            'Messages': FieldValue.arrayUnion([
              {
                'text': 'Someone sent you a friend request!',
                'type': 'friend request received',
                'username': widget.username,
                'timestamp': FieldValue.serverTimestamp()
              }
            ]),
            'NewMessages': true,
          });
        }
      } else {
        await firestore.collection('Users').doc(friendUsername).set({
          'Requests': [widget.username],
          'Messages': [
            {
              'text': 'Someone sent you a friend request!',
              'type': 'friend request received',
              'username': widget.username,
              'timestamp': FieldValue.serverTimestamp()
            }
          ],
          'NewMessages': true,
        });
      }

      // Send a message to the requester
      DocumentReference userDocRef =
          firestore.collection('Users').doc(widget.username);
      await userDocRef.update({
        'Messages': FieldValue.arrayUnion([
          {
            'text': 'You sent a friend request to $friendUsername.',
            'type': 'friend request sent',
            'username': friendUsername,
            'timestamp': FieldValue.serverTimestamp()
          }
        ]),
        'NewMessages': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$friendUsername added to your friend requests list'),
      ));

      setState(() {
        searchResults.remove(friendUsername);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$friendUsername is already in your friends list'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: WideTextBox(
                    hintText: 'Enter Username',
                    controller: searchController,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchUsers(searchController.text),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  String username = searchResults[index];
                  return ListTile(
                    title: Text(username),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => addFriend(username),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
