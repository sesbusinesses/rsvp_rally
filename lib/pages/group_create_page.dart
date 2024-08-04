import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/group_image_display.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class GroupCreatePage extends StatefulWidget {
  final String username;
  final double rating;

  const GroupCreatePage({
    super.key,
    required this.username,
    required this.rating,
  });

  @override
  GroupCreatePageState createState() => GroupCreatePageState();
}

class GroupCreatePageState extends State<GroupCreatePage> {
  List<String> members = [];
  bool isLoading = false;
  TextEditingController groupNameController = TextEditingController();

  Future<void> createGroup() async {
    String groupName = groupNameController.text;

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter a group name', style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    }
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please invite at least one person',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentReference groupRef = firestore.collection('Groups').doc();

      Map<String, dynamic> groupData = {
        'Name': groupName,
        'Host': widget.username,
        'members': members,
      };

      await groupRef.set(groupData);

      WriteBatch batch = firestore.batch();

      DocumentReference hostDocRef =
          firestore.collection('Users').doc(widget.username);
      batch.update(hostDocRef, {
        'Groups': FieldValue.arrayUnion([groupRef.id])
      });

      Timestamp timestamp = Timestamp.now();
      DocumentSnapshot hostDoc =
          await firestore.collection('Users').doc(widget.username).get();
      String hostFirstName = hostDoc['FirstName'] ?? widget.username;
      String hostLastName = hostDoc['LastName'] ?? '';

      for (String member in members) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(member);
        Map<String, dynamic> updateData = {
          'Groups': FieldValue.arrayUnion([groupRef.id]),
        };

        updateData['Messages'] = FieldValue.arrayUnion([
          {
            'text':
                '$hostFirstName $hostLastName has added you to the group $groupName.',
            'type': 'group invitation',
            'groupID': groupRef.id,
            'timestamp': timestamp
          }
        ]);
        updateData['NewMessages'] = true;

        batch.update(userDocRef, updateData);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Group created successfully', style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to create group: $e', style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Create Group', style: AppColors.topStyle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 0, bottom: 16),
              child: IconButton(
                iconSize: 50,
                icon: Icon(
                  Icons.check_circle,
                  color: getInterpolatedColor(widget.rating),
                ),
                onPressed: () {
                  createGroup();
                },
              )),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: screenSize.width * 0.075),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    AppColors.light, // Light background color
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: getInterpolatedColor(
                                      widget.rating), // Adjust color as needed
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05),
                              child: Column(children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Group Name',
                                  style: AppColors.titleStyle,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                WideTextBox(
                                  hintText: 'Group Name',
                                  controller: groupNameController,
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ]),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            AttendeeEntrySection(
                              rating: widget.rating,
                              username: widget.username,
                              onAttendeesChanged: (newMembers) {
                                members = newMembers.keys.toList();
                              },
                              existingAttendees: {
                                for (var member in members) member: ''
                              },
                            ),
                            const SizedBox(height: 170),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
