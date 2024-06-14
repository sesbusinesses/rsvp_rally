import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/inbox_page.dart';

class ViewInboxButton extends StatelessWidget {
  final String username;
  final double userRating;

  const ViewInboxButton({
    super.key,
    required this.username,
    required this.userRating,
  });

  Future<void> setNewMessagesFalse(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(username)
        .update({'NewMessages': false});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('Users').doc(username).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Icon(
            Icons.mark_email_read_rounded,
            color: getInterpolatedColor(userRating),
            size: 50,
          );
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error,
            color: getInterpolatedColor(userRating),
            size: 50,
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Icon(
            Icons.mark_email_read_rounded,
            color: getInterpolatedColor(userRating),
            size: 50,
          );
        } else {
          DocumentSnapshot hostDoc = snapshot.data!;
          bool newMessages = hostDoc['NewMessages'] ?? false;
          return IconButton(
            iconSize: 50,
            icon: Icon(
              newMessages
                  ? Icons.mark_email_unread_rounded
                  : Icons.mark_email_read_rounded,
              color: getInterpolatedColor(userRating),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxPage(
                    userRating: userRating,
                    username: username,
                  ),
                ),
              ).then((_) => setNewMessagesFalse(context));
            },
          );
        }
      },
    );
  }
}
