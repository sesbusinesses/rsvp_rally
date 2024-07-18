import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class UserCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserCardModel(username, viewerUsername),
      child: _UserCardContent(
        smallVersion: smallVersion,
        removePadding: removePadding,
        showUsername: showUsername,
        icon: icon,
      ),
    );
  }
}

class _UserCardContent extends StatelessWidget {
  final bool smallVersion;
  final bool removePadding;
  final bool showUsername;
  final Icon? icon;

  const _UserCardContent({
    required this.smallVersion,
    required this.removePadding,
    required this.showUsername,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final model = Provider.of<UserCardModel>(context);

    return FutureBuilder<void>(
      future: model.userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading user data'),
          );
        } else {
          var userData = model.userData;
          String firstName = userData['firstName'];
          String lastName = userData['lastName'];
          String? profilePicBase64 = userData['profilePicBase64'];
          double rating = userData['rating'];

          return FutureBuilder<void>(
            future: model.friendsFuture,
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else if (friendSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading friends list'),
                );
              } else {
                bool isFriend = model.isFriend;
                bool isRequestSent = model.isRequestSent;

                if (kDebugMode) {
                  print('isFriend: $isFriend, isRequestSent: $isRequestSent');
                }

                return Container(
                  width: screenSize.width * 0.85,
                  height:
                      model.viewerUsername == "" || isFriend || isRequestSent
                          ? (smallVersion ? 50 : 80)
                          : 130,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: removePadding
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
                                  radius: smallVersion ? 15 : 30,
                                  backgroundImage: profilePicBase64 != null
                                      ? MemoryImage(
                                          base64Decode(profilePicBase64))
                                      : null,
                                  child: profilePicBase64 == null
                                      ? Icon(Icons.add,
                                          size: smallVersion ? 15 : 30,
                                          color: AppColors.accentDark)
                                      : null,
                                ),
                              ),
                              if (!smallVersion)
                                Positioned(
                                  bottom: -3,
                                  right: -6,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.transparent,
                                    child: Text(
                                      model.getEmoji(rating),
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
                                if (showUsername && !smallVersion)
                                  Text(model.username,
                                      style: AppColors.usernameStyle),
                              ],
                            ),
                          ),
                          if (icon != null) icon!,
                          if (icon != null) const SizedBox(width: 15),
                        ],
                      ),
                      if (model.viewerUsername != "" &&
                          !isFriend &&
                          !isRequestSent)
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          child: WideButton(
                            buttonText: "Add Friend",
                            onPressed: () {
                              model.addFriend(context, model.username);
                            },
                            rating: rating,
                            smallVersion: true,
                          ),
                        ),
                    ],
                  ),
                );
              }
            },
          );
        }
      },
    );
  }
}

class UserCardModel extends ChangeNotifier {
  final String username;
  final String viewerUsername;
  late Future<void> userDataFuture;
  late Future<void> friendsFuture;
  Map<String, dynamic> userData = {};
  bool isFriend = false;
  bool isRequestSent = false;

  UserCardModel(this.username, this.viewerUsername) {
    userDataFuture = fetchUserData();
    friendsFuture = viewerUsername.isNotEmpty
        ? fetchFriendsAndRequests()
        : Future.value(); // Default future if viewerUsername is empty
  }

  Future<void> fetchUserData() async {
    if (username.isEmpty) {
      throw Exception("Username is empty");
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      this.userData = {
        'firstName': userData['FirstName'] ?? "",
        'lastName': userData['LastName'] ?? "",
        'profilePicBase64': userData['ProfilePic'],
        'rating': double.tryParse(userData['Rating'].toString()) ?? 0.0,
      };
    } else {
      throw Exception("User not found");
    }
  }

  Future<void> fetchFriendsAndRequests() async {
    if (viewerUsername.isEmpty) {
      throw Exception("Viewer username is empty");
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(viewerUsername).get();
      DocumentSnapshot viewedUserDoc =
          await firestore.collection('Users').doc(username).get();

      if (userDoc.exists && viewedUserDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> viewedUserData =
            viewedUserDoc.data() as Map<String, dynamic>;

        List<String> friendsUsernames = List.from(userData['Friends'] ?? []);
        List<String> requestsUsernames =
            List.from(viewedUserData['Requests'] ?? []);

        isRequestSent = requestsUsernames.contains(viewerUsername);
        isFriend =
            friendsUsernames.contains(username) || viewerUsername == username;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching friends or requests: $e");
      }
    }
  }

  String getEmoji(double rating) {
    if (rating <= 0.25) return '😡'; // Mad
    if (rating <= 0.5) return '😕'; // Confused
    if (rating <= 0.75) return '😐'; // Straight face
    return '😊'; // Joyful
  }

  Future<void> addFriend(BuildContext context, String friendUsername) async {
    if (friendUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend username is empty', style: AppColors.bodyStyle),
        backgroundColor: AppColors.accentLight,
      ));
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Timestamp timestamp = Timestamp.now();

    DocumentSnapshot friendDoc =
        await firestore.collection('Users').doc(friendUsername).get();
    if (friendDoc.exists) {
      List<dynamic> friendRequestsList = friendDoc['Requests'] ?? [];
      if (!friendRequestsList.contains(viewerUsername)) {
        friendRequestsList.add(viewerUsername);
        await firestore.collection('Users').doc(friendUsername).update({
          'Requests': friendRequestsList,
          'Messages': FieldValue.arrayUnion([
            {
              'text': 'Someone sent you a friend request!',
              'type': 'friend request received',
              'username': viewerUsername,
              'timestamp': timestamp,
              'active': true,
            }
          ]),
          'NewMessages': true,
        });
        DocumentReference userDocRef =
            firestore.collection('Users').doc(viewerUsername);
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

        isFriend = true;
        isRequestSent = true;
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Friend request sent to $friendUsername',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ));
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
}
