import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
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
  List<Map<String, dynamic>> friends = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllUsernames();
    fetchFriends();

    // Add listener to the searchController
    searchController.addListener(() {
      searchUsers(searchController.text);
    });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    searchController.dispose();
    super.dispose();
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

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(widget.username).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<String> friendsUsernames = List.from(userData['Friends'] ?? []);
        List<Map<String, dynamic>> friendsList = [];

        for (String friendUsername in friendsUsernames) {
          DocumentSnapshot friendDoc =
              await firestore.collection('Users').doc(friendUsername).get();

          if (friendDoc.exists) {
            Map<String, dynamic> friendData =
                friendDoc.data() as Map<String, dynamic>;
            friendsList.add({
              'username': friendUsername,
              'firstName': friendData['FirstName'] ?? "",
              'lastName': friendData['LastName'] ?? "",
              'rating': double.tryParse(friendData['Rating'].toString()) ?? 0.0,
            });
          }
        }

        friendsList.sort((a, b) => b['rating'].compareTo(a['rating']));
        setState(() {
          friends = friendsList;
        });
        return friendsList;
      }
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print("Error fetching friends: $e");
      }
    }
    return [];
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
                username.toLowerCase().startsWith(query.toLowerCase()) &&
                !friends.any((friend) => friend['username'] == username))
            .toList();
      });
    }
  }

  Future<void> addFriend(String friendUsername) async {
    if (!friends.any((friend) => friend['username'] == friendUsername)) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      Timestamp timestamp = Timestamp.now();

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
                'timestamp': timestamp,
                'active': true,
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
              'timestamp': timestamp,
              'active': true,
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
            'timestamp': timestamp,
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
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text('Add Friends'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: screenSize.width * 0.85,
            child: WideTextBox(
              hintText: 'Search for friends',
              controller: searchController,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
              child: SizedBox(
            width: screenSize.width * 0.95,
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                String username = searchResults[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: ListTile(
                      minLeadingWidth: 0,
                      minVerticalPadding: 0,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: screenSize.width * 0.05),
                      title: UserCard(username: username),
                      trailing: GestureDetector(
                          child: const Icon(Icons.add),
                          onTap: () => addFriend(username))),
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}
