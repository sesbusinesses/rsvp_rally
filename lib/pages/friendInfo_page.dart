import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/custom_switcher.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/feed_card.dart';

class FriendInfoPage extends StatefulWidget {
  final String username;
  final double rating;

  const FriendInfoPage({
    Key? key,
    required this.username,
    required this.rating,
  }) : super(key: key);

  @override
  _FriendInfoPageState createState() => _FriendInfoPageState();
}

class _FriendInfoPageState extends State<FriendInfoPage> {
  int selectedIndex = 0;
  List<Map<String, dynamic>> friendsData = [];
  List<Map<String, dynamic>> filteredFriends = [];
  List<DocumentSnapshot> feeds = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFriends().then((friends) {
      if (mounted) {
        setState(() {
          friendsData = friends;
          filteredFriends = friendsData;
        });
      }
    });
    fetchFeeds();
  }

  Future<Map<String, dynamic>> _getProfileData(String username) async {
    String? fullName = await getFullName(username);
    String? profilePicBase64 = await pullProfilePicture(username);

    return {
      'fullName': fullName ?? 'N/A',
      'profilePicBase64': profilePicBase64,
    };
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
      if (kDebugMode) {
        print("Error fetching friends: $e");
      }
    }
    return [];
  }

  Future<void> fetchFeeds() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Feeds')
          .where('user', isEqualTo: widget.username)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        feeds = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle the error appropriately in your app
      print('Error fetching feeds: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getProfileData(widget.username),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (profileSnapshot.hasError) {
            return Center(child: Text('Error loading profile data'));
          } else if (profileSnapshot.hasData) {
            var profileData = profileSnapshot.data!;
            String? profilePicBase64 = profileData['profilePicBase64'];
            String fullName = profileData['fullName'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Shop')
                  .doc('freakText')
                  .get(),
              builder: (context, freakSnapshot) {
                if (freakSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (freakSnapshot.hasError) {
                  return Center(child: Text('Error loading freak status'));
                } else {
                  bool isFreak = false;
                  if (freakSnapshot.hasData && freakSnapshot.data != null) {
                    Map<String, dynamic> freakData =
                        freakSnapshot.data!.data() as Map<String, dynamic>;
                    isFreak = freakData[widget.username] == true;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: screenSize.width * 0.85,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: getInterpolatedColor(widget.rating),
                              width: AppColors.borderWidth,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundImage:
                                              profilePicBase64 != null
                                                  ? MemoryImage(base64Decode(
                                                      profilePicBase64))
                                                  : null,
                                          child: profilePicBase64 == null
                                              ? const Icon(Icons.add,
                                                  size: 50, color: Colors.grey)
                                              : null,
                                        ),
                                        if (profilePicBase64 != null)
                                          Positioned(
                                            bottom: 5,
                                            right: -3,
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Image.asset(
                                                getEmoji(widget.rating),
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      fullName,
                                      style: AppColors.titleStyle,
                                    ),
                                    Text(
                                      widget.username,
                                      style: AppColors.usernameStyle,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              if (isFreak)
                                Positioned(
                                  top: 15,
                                  right: 15,
                                  child: Text(
                                    "𝓯𝓻𝓮𝓪𝓴𝔂",
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          getInterpolatedColor(widget.rating),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        CustomTabSwitcher(
                          tabs: [Icons.rss_feed, Icons.people],
                          subtitles: ['Feed', 'Friends'],
                          selectedIndex: selectedIndex,
                          onTabChanged: (index) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          userRating: widget.rating,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          iconSize: 30,
                        ),
                        if (selectedIndex == 1) _buildFriendsList(),
                        if (selectedIndex == 0) _buildFeed(),
                      ],
                    ),
                  );
                }
              },
            );
          }
          return Center(child: Text('No profile data found'));
        },
      ),
    );
  }

  Widget _buildFriendsList() {
    return Column(
      children: [
        if (filteredFriends.isNotEmpty)
          ...filteredFriends.map((friendData) => UserCard(
                username: friendData['username'],
              )),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFeed() {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 15));
    }

    if (feeds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'No feeds available.',
          style: AppColors.bodyStyle,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 100),
      child: ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        var feed = feeds[index];
        return FeedCard(
          imageUrl: feed['imageUrl'],
          description: feed['description'],
          user: feed['user'],
          likes: List<String>.from(feed['likes']),
          chat: List<Map<String, dynamic>>.from(feed['chat']),
          postId: feed.id,
          isUserPost: feed['user'] == widget.username,
          username: widget.username,
          showDeleteButton: false, // Hide the delete button
        );
      },
    ));
  }
}
