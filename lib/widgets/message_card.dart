import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageCard extends StatefulWidget {
  final String username;
  final double rating;
  final Map<String, dynamic> messageData;

  const MessageCard({
    super.key,
    required this.username,
    required this.rating,
    required this.messageData,
  });

  @override
  MessageCardState createState() => MessageCardState();
}

class MessageCardState extends State<MessageCard> {
  Future<void> acceptFriendRequest(String friendUsername) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Add friend to user's friend list and send acceptance message
    DocumentReference userDocRef =
        firestore.collection('Users').doc(widget.username);
    await userDocRef.update({
      'Friends': FieldValue.arrayUnion([friendUsername]),
      'Messages': FieldValue.arrayUnion([
        {
          'text': 'You accepted the friend request from $friendUsername!',
          'type': 'friend request update',
          'username': friendUsername,
        }
      ]),
      'Requests': FieldValue.arrayRemove([friendUsername]),
    });

    // Add user to friend's friend list and send acceptance message
    DocumentReference friendDocRef =
        firestore.collection('Users').doc(friendUsername);
    await friendDocRef.update({
      'Friends': FieldValue.arrayUnion([widget.username]),
      'Messages': FieldValue.arrayUnion([
        {
          'text': '${widget.username} accepted your friend request!',
          'type': 'friend request update',
          'username': widget.username,
        }
      ]),
      'Requests': FieldValue.arrayRemove([widget.username]),
    });

    // Refresh the UI
    setState(() {});
  }

  Future<void> declineFriendRequest(String friendUsername) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Remove the friend request message from user's messages
    DocumentReference userDocRef =
        firestore.collection('Users').doc(widget.username);
    await userDocRef.update({
      'Messages': FieldValue.arrayUnion([
        {
          'text': 'You have declined the friend request from $friendUsername.',
          'type': 'friend request update',
          'username': friendUsername,
        }
      ]),
      'Requests': FieldValue.arrayRemove([friendUsername]),
    });

    // Send decline message to the requester
    DocumentReference friendDocRef =
        firestore.collection('Users').doc(friendUsername);
    await friendDocRef.update({
      'Messages': FieldValue.arrayUnion([
        {
          'text': '${widget.username} has declined your friend request.',
          'type': 'friend request update',
          'username': widget.username,
        }
      ]),
    });

    // Refresh the UI
    setState(() {});
  }

  Future<bool> isInRequestsList() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.username)
        .get();
    if (userDoc.exists) {
      List<dynamic> requests = userDoc['Requests'] ?? [];
      return requests.contains(widget.messageData['username']);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    String messageType = widget.messageData['type'] ?? 'Unknown';
    String messageText = widget.messageData['text'] ?? '';
    String additionalInfo = '';

    if (messageType == 'friend request received' ||
        messageType == 'friend request sent' ||
        messageType == 'friend request update') {
      additionalInfo = 'From: ${widget.messageData['username']}';
    } else if (messageType == 'event invitation' ||
        messageType == 'poll reminder') {
      additionalInfo = 'Event ID: ${widget.messageData['eventID']}';
    }

    return Container(
      width: screenSize.width * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
      child: messageType == 'event invitation' || messageType == 'poll reminder'
          ? GestureDetector(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      messageText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.arrow_forward_ios,
                      color: getInterpolatedColor(widget.rating)),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PollPage(
                      username: widget.username,
                      rating: widget.rating,
                      eventID: widget.messageData['eventID'],
                    ),
                  ),
                );
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageText,
                  style: const TextStyle(fontSize: 16),
                ),
                if (messageType == 'friend request received' ||
                    messageType == 'friend request sent') ...[
                  UserCard(username: widget.messageData['username']),
                  FutureBuilder<bool>(
                    future: isInRequestsList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      } else if (snapshot.hasData && snapshot.data!) {
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WideButton(
                                  buttonText: 'Accept',
                                  rating: widget.rating,
                                  onPressed: () => acceptFriendRequest(
                                      widget.messageData['username']),
                                ),
                                WideButton(
                                  buttonText: 'Decline',
                                  rating: widget.rating,
                                  onPressed: () => declineFriendRequest(
                                      widget.messageData['username']),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ]
              ],
            ),
    );
  }
}
