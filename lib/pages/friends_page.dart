import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/groups_page.dart';
import 'package:rsvp_rally/widgets/add_friend_button.dart';
import 'package:rsvp_rally/widgets/custom_switcher.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/view_settings_button.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/pages/add_friends_page.dart';
import 'package:rsvp_rally/widgets/profileEditor.dart';

class FriendsPage extends StatefulWidget {
  final String username;
  final double rating;

  const FriendsPage({super.key, required this.username, required this.rating});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> friendsData = [];
  List<Map<String, dynamic>> filteredFriends = [];
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    fetchFriends().then((friends) {
      setState(() {
        friendsData = friends;
        filteredFriends = friendsData;
      });
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(widget.username).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<String> friendsUsernames = List.from(userData['Friends'] ?? []);
        List<Map<String, dynamic>> friends = [];

        // Batch fetch all friends' documents
        var friendsDocs = await firestore
            .collection('Users')
            .where(FieldPath.documentId, whereIn: friendsUsernames)
            .get();

        for (var friendDoc in friendsDocs.docs) {
          if (friendDoc.exists) {
            Map<String, dynamic> friendData = friendDoc.data();
            friends.add({
              'username': friendDoc.id,
              'firstName': friendData['FirstName'] ?? "",
              'lastName': friendData['LastName'] ?? "",
              'rating': double.tryParse(friendData['Rating'].toString()) ?? 0.0,
            });
          }
        }

        friends.sort((a, b) => b['rating'].compareTo(a['rating']));
        return friends;
      }
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print("Error fetching friends: $e");
      }
    }
    return [];
  }

  void filterFriends(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredFriends = friendsData;
      });
    } else {
      String lowerCaseQuery = query.toLowerCase();

      List<Map<String, dynamic>> temp = friendsData.where((friend) {
        return friend['username'].toLowerCase().contains(lowerCaseQuery) ||
            friend['firstName'].toLowerCase().contains(lowerCaseQuery) ||
            friend['lastName'].toLowerCase().contains(lowerCaseQuery);
      }).toList();

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

  void _onTabChanged(int index) {
    if (index != _selectedIndex) {
      _slideAnimation = Tween<Offset>(
        begin: index > _selectedIndex
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: CustomTabSwitcher(
          tabs: const ['My Info', 'Groups'],
          selectedIndex: _selectedIndex,
          onTabChanged: _onTabChanged,
          userRating: widget.rating,
          padding: const EdgeInsets.only(top: 8.0), // Adjust padding as needed
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          ViewSettingsButton(
            username: widget.username,
            userRating: widget.rating,
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: _selectedIndex == 0
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfileEditor(
                          username: widget.username,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              width: screenSize.width * 0.85,
                              decoration: BoxDecoration(
                                color: Colors
                                    .transparent, // Light background color
                                border: Border.all(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: WideTextBox(
                                          hintText: 'Browse Friends...',
                                          controller: searchController,
                                          onChanged: (value) => filterFriends(
                                              searchController.text),
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              8), // Gap between text box and button
                                      AddFriendsButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddFriendsPage(
                                                      username:
                                                          widget.username),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (filteredFriends.isNotEmpty)
                                    ...filteredFriends.map((friendData) =>
                                        UserCard(
                                            username: friendData['username'])),
                                  if (filteredFriends.isEmpty &&
                                      friendsData.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Text(
                                        'You don\'t have any friends yet. Click the button below to find some!',
                                        style: AppColors.bodyStyle,
                                      ),
                                    ),
                                  if (filteredFriends.isEmpty &&
                                      friendsData.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: Text(
                                        'You don\'t have any friends for this search. Click the button below to find some!',
                                        style: AppColors.bodyStyle,
                                      ),
                                    ),
                                  const SizedBox(height: 80)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : GroupsPage(), // New GroupsPage
      ),
    );
  }
}
