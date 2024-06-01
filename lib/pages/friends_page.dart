import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class FriendsPage extends StatefulWidget {
  final String username;

  const FriendsPage({super.key, required this.username});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
  List<String> friendsUsernames = [];
  List<String> filteredFriends = [];
  TextEditingController searchController = TextEditingController();

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
      setState(() {
        friendsUsernames = List.from(userData['Friends'] ?? []);
        filteredFriends = friendsUsernames;
      });
    }
  }

  void filterFriends(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFriends = friendsUsernames;
      });
    } else {
      List<String> temp = [];
      for (String friend in friendsUsernames) {
        if (friend.toLowerCase().contains(query.toLowerCase())) {
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
        title: const Text('Friends'),
        backgroundColor: Colors.transparent, // AppBar color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFfefdfd), Color(0xFF5f42b2)], // White to purple gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserCard(username: widget.username),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: screenSize.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Light background color
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Add Friends', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: WideTextBox(
                            hintText: 'Search for friends...',
                            controller: searchController,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () => filterFriends(searchController.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.075, vertical: 10),
                    width: screenSize.width * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Light background color
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Friends', style: TextStyle(fontSize: 20)),
                        ...filteredFriends.map(
                            (friendUsername) => UserCard(username: friendUsername)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
