import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/group_image_display.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class GroupEditPage extends StatefulWidget {
  final String groupID;
  final String username;
  final double rating;

  const GroupEditPage({
    super.key,
    required this.groupID,
    required this.username,
    required this.rating,
  });

  @override
  GroupEditPageState createState() => GroupEditPageState();
}

class GroupEditPageState extends State<GroupEditPage> {
  List<String> members = [];
  List<String> originalMembers = [];
  String groupName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGroupData();
  }

  Future<void> loadGroupData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot groupSnapshot =
        await firestore.collection('Groups').doc(widget.groupID).get();

    if (groupSnapshot.exists) {
      Map<String, dynamic> groupData =
          groupSnapshot.data() as Map<String, dynamic>;

      setState(() {
        members = List<String>.from(groupData['members'] ?? []);
        originalMembers = List<String>.from(members);
        groupName = groupData['Name'] ?? 'the group';
        isLoading = false;
      });
    }
  }

  Future<void> updateGroup() async {
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please invite at least one person',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    Map<String, dynamic> groupData = {
      'members': members,
    };

    try {
      await firestore
          .collection('Groups')
          .doc(widget.groupID)
          .update(groupData);

      WriteBatch batch = firestore.batch();

      DocumentReference hostDocRef =
          firestore.collection('Users').doc(widget.username);
      batch.update(hostDocRef, {
        'Groups': FieldValue.arrayUnion([widget.groupID])
      });

      Timestamp timestamp = Timestamp.now();
      DocumentSnapshot hostDoc =
          await firestore.collection('Users').doc(widget.username).get();
      String hostFirstName = hostDoc['FirstName'] ?? widget.username;
      String hostLastName = hostDoc['LastName'] ?? '';
      List<String> removedMembers =
          originalMembers.where((member) => !members.contains(member)).toList();

      for (String friend in removedMembers) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(friend);
        batch.update(userDocRef, {
          'Messages': FieldValue.arrayUnion([
            {
              'text':
                  '$hostFirstName $hostLastName has removed you from the group $groupName.',
              'type': 'group removal',
              'groupID': widget.groupID,
              'timestamp': timestamp
            }
          ]),
          'NewMessages': true,
          'Groups': FieldValue.arrayRemove([widget.groupID])
        });
      }

      for (String member in members) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(member);
        Map<String, dynamic> updateData = {
          'Groups': FieldValue.arrayUnion([widget.groupID]),
        };

        if (!originalMembers.contains(member)) {
          updateData['Messages'] = FieldValue.arrayUnion([
            {
              'text':
                  '$hostFirstName $hostLastName has added you to the group $groupName.',
              'type': 'group invitation',
              'groupID': widget.groupID,
              'timestamp': timestamp
            }
          ]);
          updateData['NewMessages'] = true;
        }

        batch.update(userDocRef, updateData);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Group updated successfully', style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update group: $e',
                  style: AppColors.bodyStyle),
              backgroundColor: AppColors.accentLight),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Edit Group', style: AppColors.topStyle),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 15))
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
                              vertical: 10,
                              horizontal: screenSize.width * 0.075),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                  width: screenSize.width * 0.85,
                                  height: screenSize.width * 0.85,
                                  decoration: BoxDecoration(
                                    color: AppColors
                                        .light, // Dark background color
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: getInterpolatedColor(widget
                                          .rating), // Adjust color as needed
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
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text('Group Image',
                                            style: AppColors.titleStyle),
                                        SizedBox(
                                          width: screenSize.width * 0.6,
                                          height: screenSize.width * 0.6,
                                          child: GroupImageDisplay(
                                            groupID: widget.groupID,
                                            clickable: true,
                                          ),
                                        )
                                      ])),
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 10),
                              WideButton(
                                rating: widget.rating,
                                buttonText: 'Update Group',
                                onPressed: updateGroup,
                              ),
                              const SizedBox(height: 10),
                              WideButton(
                                rating: widget.rating,
                                buttonText: 'Delete Group',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        surfaceTintColor:
                                            getInterpolatedColor(widget.rating),
                                        title: Text('Delete Group',
                                            style: AppColors.titleStyle),
                                        content: Text(
                                          'Are you sure you want to delete this group? This action cannot be undone.',
                                          style: AppColors.bodyStyle,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Cancel',
                                              style:
                                                  AppColors.bodyStyle.copyWith(
                                                color: getInterpolatedColor(
                                                    widget.rating),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              FirebaseFirestore firestore =
                                                  FirebaseFirestore.instance;
                                              WriteBatch batch =
                                                  firestore.batch();

                                              // Remove the group ID from each member's document
                                              for (String member in members) {
                                                DocumentReference userDocRef =
                                                    firestore
                                                        .collection('Users')
                                                        .doc(member);
                                                batch.update(userDocRef, {
                                                  'Groups':
                                                      FieldValue.arrayRemove(
                                                          [widget.groupID])
                                                });
                                              }

                                              // Delete the group document
                                              DocumentReference groupDocRef =
                                                  firestore
                                                      .collection('Groups')
                                                      .doc(widget.groupID);
                                              batch.delete(groupDocRef);

                                              // Remove the group ID from the host's document
                                              DocumentReference hostDocRef =
                                                  firestore
                                                      .collection('Users')
                                                      .doc(widget.username);
                                              batch.update(hostDocRef, {
                                                'Groups':
                                                    FieldValue.arrayRemove(
                                                        [widget.groupID])
                                              });

                                              await batch.commit();

                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Delete',
                                              style:
                                                  AppColors.bodyStyle.copyWith(
                                                color: getInterpolatedColor(
                                                    widget.rating),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
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
              ));
  }
}
