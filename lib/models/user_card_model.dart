import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

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