import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/inbox_page.dart';

class ViewInboxButton extends StatelessWidget {
  final String username;
  final double userRating;
  final bool newMessages;
  final VoidCallback onInboxOpened;

  const ViewInboxButton({
    super.key,
    required this.username,
    required this.userRating,
    required this.newMessages,
    required this.onInboxOpened,
  });

  Future<void> setNewMessagesFalse(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(username)
        .update({'NewMessages': false});
  }

  @override
  Widget build(BuildContext context) {
    double leftPadding = 10;
    double topPadding = 10;
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding, top: topPadding),
        child: Icon(
          newMessages
              ? Icons.mark_email_unread_rounded
              : Icons.mark_email_read_rounded,
          color: getInterpolatedColor(userRating),
          size: 50,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InboxPage(
              userRating: userRating,
              username: username,
            ),
          ),
        ).then((_) {
          setNewMessagesFalse(context);
          onInboxOpened();
        });
      },
    );
  }
}
