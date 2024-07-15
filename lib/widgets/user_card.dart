import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class UserCard extends StatefulWidget {
  final String username;
  final bool smallVersion;
  final Icon? icon;
  final bool removePadding;
  final bool showUsername;
  final String viewerUsername;

  const UserCard({
    super.key,
    required this.username,
    this.smallVersion = false,
    this.removePadding = false,
    this.showUsername = true,
    this.icon,
    this.viewerUsername = "",
  });

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  late Future<Map<String, dynamic>> _userDataFuture;
  late Future<List<String>> _friendsFuture;
  bool isFriend = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = fetchUserData(widget.username);
    if (widget.viewerUsername != "") {
      _friendsFuture = fetchFriends(widget.viewerUsername);
    }
  }

  Future<Map<String, dynamic>> fetchUserData(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return {
        'firstName': userData['FirstName'] ?? "",
        'lastName': userData['LastName'] ?? "",
        'profilePicBase64': userData['ProfilePic'],
        'rating': double.tryParse(userData['Rating'].toString()) ?? 0.0,
      };
    } else {
      throw Exception("User not found");
    }
  }

  Future<List<String>> fetchFriends(String viewerUsername) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(viewerUsername).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<String> friendsUsernames = List.from(userData['Friends'] ?? []);
        return friendsUsernames;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching friends: $e");
      }
    }
    return [];
  }

  String getEmoji(double rating) {
    if (rating <= 0.25) return '😡'; // Mad
    if (rating <= 0.5) return '😕'; // Confused
    if (rating <= 0.75) return '😐'; // Straight face
    return '😊'; // Joyful
  }

  Future<void> addFriend(String friendUsername) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Timestamp timestamp = Timestamp.now();

    DocumentSnapshot friendDoc =
        await firestore.collection('Users').doc(friendUsername).get();
    if (friendDoc.exists) {
      List<dynamic> friendRequestsList = friendDoc['Requests'] ?? [];
      if (!friendRequestsList.contains(widget.viewerUsername)) {
        friendRequestsList.add(widget.viewerUsername);
        await firestore.collection('Users').doc(friendUsername).update({
          'Requests': friendRequestsList,
          'Messages': FieldValue.arrayUnion([
            {
              'text': 'Someone sent you a friend request!',
              'type': 'friend request received',
              'username': widget.viewerUsername,
              'timestamp': timestamp,
              'active': true,
            }
          ]),
          'NewMessages': true,
        });
        DocumentReference userDocRef =
            firestore.collection('Users').doc(widget.viewerUsername);
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
          content: Text('$friendUsername added to your friend requests list',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ));
        setState(() {
          isFriend = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You already sent a friend request to $friendUsername',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('$friendUsername doesn\'t exist', style: AppColors.bodyStyle),
        backgroundColor: AppColors.accentLight,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading user data'),
          );
        } else if (snapshot.hasData) {
          var userData = snapshot.data!;
          String firstName = userData['firstName'];
          String lastName = userData['lastName'];
          String? profilePicBase64 = userData['profilePicBase64'];
          double rating = userData['rating'];

          return FutureBuilder<List<String>>(
            future: _friendsFuture,
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else if (friendSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading friends list'),
                );
              } else if (friendSnapshot.hasData) {
                List<String> friends = friendSnapshot.data!;
                isFriend = friends.contains(widget.username) ||
                    widget.viewerUsername == widget.username;

                return Container(
                  width: screenSize.width * 0.85,
                  height: widget.viewerUsername == "" || isFriend
                      ? (widget.smallVersion ? 50 : 80)
                      : 130,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: widget.removePadding
                      ? const EdgeInsets.symmetric(vertical: 0)
                      : const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: getInterpolatedColor(rating),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Stack(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: widget.smallVersion ? 15 : 30,
                                  backgroundImage: profilePicBase64 != null
                                      ? MemoryImage(
                                          base64Decode(profilePicBase64))
                                      : null,
                                  child: profilePicBase64 == null
                                      ? Icon(Icons.add,
                                          size: widget.smallVersion ? 15 : 30,
                                          color: AppColors.accentDark)
                                      : null,
                                ),
                              ),
                              if (profilePicBase64 != null &&
                                  !widget.smallVersion)
                                Positioned(
                                  bottom: -3,
                                  right: -6,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.transparent,
                                    child: Text(
                                      getEmoji(rating),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$firstName $lastName",
                                  style: AppColors.bodyStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.showUsername && !widget.smallVersion)
                                  Text(widget.username,
                                      style: AppColors.usernameStyle),
                              ],
                            ),
                          ),
                          if (widget.icon != null) widget.icon!,
                          if (widget.icon != null) const SizedBox(width: 15),
                        ],
                      ),
                      if (widget.viewerUsername != "" && !isFriend)
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          child: WideButton(
                            buttonText: "Add Friend",
                            onPressed: () {
                              addFriend(widget.username);
                              setState(() {
                                isFriend = true;
                              });
                            },
                            rating: rating,
                            smallVersion: true,
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Container();
            },
          );
        }
        return Container();
      },
    );
  }
}
