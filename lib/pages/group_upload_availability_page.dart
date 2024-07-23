import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_availability_selector.dart';

class GroupUploadAvailabilityPage extends StatelessWidget {
  final String groupID;
  final String username;
  final double userRating;

  const GroupUploadAvailabilityPage({
    super.key,
    required this.groupID,
    required this.username,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Next Week's Availability", style: AppColors.topStyle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
            child: Text('Select your availability for next week',
                style: AppColors.bodyStyle),
          ),
          Expanded(
            child: GroupAvailabilitySelector(
              isEditable: true,
              groupID: groupID,
              username: username,
              userRating: userRating,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
            child: Text('Availability is due 11:59 PM every Sunday',
                style: AppColors.bodyStyle),
          ),
        ],
      ),
    );
  }
}
