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
          title: Text("This Week's Availability", style: AppColors.topStyle),
        ),
        body: Column(children: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
          //   child:
          //       Text('This week\'s availability', style: AppColors.bodyStyle),
          // ),
          Expanded(
            child: GroupAvailabilitySelector(
              isEditable: false,
              groupID: groupID,
              userRating: userRating,
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30),
          //   child: Text('The darker the color the more people are available',
          //       style: AppColors.bodyStyle),
          // ),
        ]));
  }
}
