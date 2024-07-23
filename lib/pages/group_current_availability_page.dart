import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_availability_selector.dart';

class GroupCurrentAvailabilityPage extends StatelessWidget {
  final String groupID;
  final double userRating;

  const GroupCurrentAvailabilityPage({
    super.key,
    required this.groupID,
    required this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Current Week's Availability", style: AppColors.topStyle),
      ),
      body: GroupAvailabilitySelector(
        isEditable: false,
        groupID: groupID,
        userRating: userRating,
      ),
    );
  }
}
