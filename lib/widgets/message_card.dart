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
    Timestamp timestamp = Timestamp.now();

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
          'timestamp': timestamp,
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
          'timestamp': timestamp,
        }
      ]),
      'Requests': FieldValue.arrayRemove([widget.username]),
    });

    // Refresh the UI
    setState(() {});

    setMessageUnactive();
  }

  Future<void> declineFriendRequest(String friendUsername) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Timestamp timestamp = Timestamp.now();

    // Remove the friend request message from user's messages
    DocumentReference userDocRef =
        firestore.collection('Users').doc(widget.username);
    await userDocRef.update({
      'Messages': FieldValue.arrayUnion([
        {
          'text': 'You have declined the friend request from $friendUsername.',
          'type': 'friend request update',
          'username': friendUsername,
          'timestamp': timestamp,
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
          'timestamp': timestamp,
        }
      ]),
    });

    // Refresh the UI
    setState(() {});

    setMessageUnactive();
  }

  void setMessageUnactive() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDocRef =
        firestore.collection('Users').doc(widget.username);

    // Retrieve the user's messages
    DocumentSnapshot userDoc = await userDocRef.get();
    List<dynamic> messages = userDoc['Messages'] ?? [];

    // Find the matching message and update its active status
    for (var message in messages) {
      if (message.toString() == widget.messageData.toString()) {
        message['active'] = false;
        break;
      }
    }

    // Update the user's messages
    await userDocRef.update({
      'Messages': messages,
    });
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

  Future<bool> isEventActive(String eventID) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.username)
        .get();
    if (userDoc.exists) {
      List<dynamic> events = userDoc['Events'] ?? [];
      return events.contains(eventID);
    }
    return false;
  }

  void handleEventTap(String eventID, String messageType) async {
    bool eventActive = await isEventActive(eventID);
    if (eventActive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => messageType == 'event invitation'
              ? DetailsPage(
                  username: widget.username,
                  userRating: widget.rating,
                  eventID: eventID,
                )
              : PollPage(
                  username: widget.username,
                  rating: widget.rating,
                  eventID: eventID,
                ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The event was cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    String messageType = widget.messageData['type'] ?? 'Unknown';
    String messageText = widget.messageData['text'] ?? '';
    String additionalInfo = '';
    bool active = false;

    if (messageType == 'friend request received' ||
        messageType == 'friend request sent' ||
        messageType == 'friend request update') {
      additionalInfo = 'From: ${widget.messageData['username']}';
      active = widget.messageData['active'] ?? false;
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
                handleEventTap(widget.messageData['eventID'], messageType);
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
                      } else if (snapshot.hasData && snapshot.data! && active) {
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                    child: WideButton(
                                  buttonText: 'Accept',
                                  rating: widget.rating,
                                  onPressed: () => acceptFriendRequest(
                                      widget.messageData['username']),
                                )),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: WideButton(
                                  buttonText: 'Decline',
                                  rating: widget.rating,
                                  onPressed: () => declineFriendRequest(
                                      widget.messageData['username']),
                                )),
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
