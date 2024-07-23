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
        title: Text("Upload Upcoming Week's Availability",
            style: AppColors.topStyle),
      ),
      body: GroupAvailabilitySelector(
        isEditable: true,
        groupID: groupID,
        username: username,
        userRating: userRating,
      ),
    );
  }
}
