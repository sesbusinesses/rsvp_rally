import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/group_page_view.dart';
import 'package:rsvp_rally/widgets/group_image_display.dart';
// import 'package:rsvp_rally/widgets/group_image_display.dart';

class GroupCard extends StatefulWidget {
  final String groupID;
  final double userRating;
  final String username;

  const GroupCard({
    super.key,
    required this.groupID,
    required this.userRating,
    required this.username,
  });

  @override
  GroupCardState createState() => GroupCardState();
}

class GroupCardState extends State<GroupCard> {
  String groupName = "";
  String groupHost = "";
  String groupMembers = "";
  bool groupExists = true;

  @override
  void initState() {
    super.initState();
    fetchGroupData();
  }

  Future<void> fetchGroupData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot groupDoc =
        await firestore.collection('Groups').doc(widget.groupID).get();

    if (groupDoc.exists) {
      Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          groupName = data['Name'] ?? "Group Name Not Found";
          groupHost = data['Host'] ?? "Host Not Found";
          groupMembers =
              (data['members'] as List).join(', ') ?? "Members Not Found";
        });
      }
    } else {
      log("Group not found");
      if (mounted) {
        setState(() {
          groupExists = false; // Mark the group as non-existent
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!groupExists) {
      return Container(); // Return an empty container if the group doesn't exist
    }

    Size screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupPageView(
                groupID: widget.groupID,
                userRating: widget.userRating,
                username: widget.username,
              ),
            ),
          );
        },
        child: Container(
          width: screenSize.width * 0.85,
          height: 100, // Increased height for better aesthetics
          decoration: BoxDecoration(
            color: AppColors.light, // Dark background color
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: getInterpolatedColor(
                  widget.userRating), // Add appropriate border color here
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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GroupImageDisplay(
                    groupID: widget.groupID, clickable: false), // New widget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: screenSize.width * 0.4 + 10,
                      child: Text(
                        groupName,
                        style: AppColors.titleStyle, // Light text color
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Host: $groupHost',
                      style: AppColors.lightDateStyle,
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: getInterpolatedColor(
                      widget.userRating), // Add appropriate icon color here
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
