import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/group_create_poll_page.dart';

class GroupCreatePollButton extends StatelessWidget {
  final String groupID;
  final String username;
  final double userRating;

  const GroupCreatePollButton({
    super.key,
    required this.groupID,
    required this.username,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GroupCreatePollPage(
                    groupID: groupID,
                    username: username,
                    userRating: userRating,
                  )),
        );
      },
      backgroundColor: getInterpolatedColor(userRating),
      child: const Icon(Icons.add, color: Color(0xFFfefdfd)),
    );
  }
}
