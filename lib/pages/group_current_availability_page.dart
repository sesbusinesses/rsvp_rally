import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_availability_selector.dart';

class GroupCurrentAvailabilityPage extends StatelessWidget {
  final String groupID;
  final double userRating;
  final String username;

  const GroupCurrentAvailabilityPage({
    super.key,
    required this.groupID,
    required this.userRating,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Our Availability", style: AppColors.topStyle),
        ),
        body: Column(children: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
          //   child: Text('The group\'s current availability:',
          //       style: AppColors.subtitleStyle),
          // ),
          Expanded(
            child: GroupAvailabilitySelector(
              isEditable: true,
              groupID: groupID,
              userRating: userRating,
              username: username,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
            child: Text('Keep your availability up to date!',
                style: AppColors.subtitleStyle),
          ),
        ]));
  }
}
