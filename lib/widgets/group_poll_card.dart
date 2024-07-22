import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/pages/group_edit_poll_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class GroupPollCard extends StatefulWidget {
  final String groupID;
  final String username;
  final Map<String, dynamic> pollData;
  final bool isHost;
  final double userRating;

  const GroupPollCard(
      {super.key,
      required this.groupID,
      required this.username,
      required this.pollData,
      required this.isHost,
      required this.userRating});

  @override
  _GroupPollCardState createState() => _GroupPollCardState();
}

class _GroupPollCardState extends State<GroupPollCard> {
  late Map<String, dynamic> pollData;
  DateTime? closeTime;

  @override
  void initState() {
    super.initState();
    pollData = widget.pollData;
    print('Poll Data on initState: $pollData');
    if (pollData['CloseTime'] != null) {
      closeTime = (pollData['CloseTime'] as Timestamp).toDate();
      print('CloseTime initialized: $closeTime');
    } else {
      print('CloseTime is null or not found');
    }
  }

  Future<void> _vote(String selectedOption) async {
    try {
      print('Voting for option: $selectedOption');
      DocumentReference groupRef =
          FirebaseFirestore.instance.collection('Groups').doc(widget.groupID);
      DocumentReference pollRef =
          groupRef.collection('Polls').doc(pollData['question']);
      DocumentSnapshot pollSnapshot = await pollRef.get();
      Map<String, dynamic>? pollResponses =
          pollSnapshot.data() as Map<String, dynamic>?;

      if (pollResponses == null) {
        throw Exception('Poll responses not found');
      }

      print('Fetched Poll Data: $pollResponses');

      // Remove user from all other options
      (pollResponses['options'] as Map<String, dynamic>?)
          ?.forEach((option, voters) {
        if (voters is List<dynamic>) {
          voters.remove(widget.username);
        }
      });

      // Add user to the selected option
      List<dynamic> selectedVoters =
          (pollResponses['options'][selectedOption] ?? []) as List<dynamic>;
      if (!selectedVoters.contains(widget.username)) {
        selectedVoters.add(widget.username);
        pollResponses['options'][selectedOption] = selectedVoters;
      }

      await pollRef.update({'options': pollResponses['options']});
      print('Poll updated in database');

      // Update local pollData state
      setState(() {
        pollData['responses']['options'] = pollResponses['options'];
        print('PollData state updated: ${pollData['responses']['options']}');
      });
    } catch (e) {
      print('Error voting: $e');
    }
  }

  Future<String?> _fetchProfilePicture(String username) async {
    return await pullProfilePicture(username);
  }

  Future<void> _confirmDelete() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: getInterpolatedColor(widget.userRating),
          title: Text('Delete Poll', style: AppColors.titleStyle),
          content: Text(
              'Are you sure you want to delete this poll? This action cannot be undone.',
              style: AppColors.bodyStyle),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: AppColors.bodyStyle.copyWith(
                      color: getInterpolatedColor(widget.userRating))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete',
                  style: AppColors.bodyStyle.copyWith(
                      color: getInterpolatedColor(widget.userRating))),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePoll();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePoll() async {
    try {
      DocumentReference groupRef =
          FirebaseFirestore.instance.collection('Groups').doc(widget.groupID);
      DocumentReference pollRef =
          groupRef.collection('Polls').doc(pollData['question']);

      await pollRef.delete();
      print('Poll deleted from database');
    } catch (e) {
      print('Error deleting poll: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    List<Widget> responseWidgets = [];

    print('Building response widgets');
    (pollData['responses']['options'] as Map<String, dynamic>?)
        ?.forEach((option, voters) {
      if (voters is List<dynamic>) {
        List<String> voterNames = List<String>.from(voters);

        responseWidgets.add(
          Column(
            children: [
              SizedBox(
                width: screenSize.width * 0.7225,
                child: WideButton(
                  buttonText: option,
                  onPressed: () {
                    if (closeTime != null &&
                        DateTime.now().isBefore(closeTime!)) {
                      _vote(option);
                    } else {
                      print(
                          'Voting not allowed, poll closed or closeTime is null');
                    }
                  },
                  rating: widget.userRating,
                ),
              ),
              if (voterNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: FutureBuilder<List<String?>>(
                    future: Future.wait(voterNames
                        .map((username) => _fetchProfilePicture(username))
                        .toList()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Wrap(
                          spacing: 8.0,
                          children: snapshot.data!.map((profilePictureData) {
                            return CircleAvatar(
                              radius: 15,
                              backgroundImage: profilePictureData != null
                                  ? MemoryImage(
                                      base64Decode(profilePictureData))
                                  : null,
                              child: profilePictureData == null
                                  ? const Icon(Icons.person,
                                      size: 20, color: Colors.grey)
                                  : null,
                            );
                          }).toList(),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                )
              else
                const SizedBox(height: 10),
            ],
          ),
        );
      }
    });

    // Format CloseTime
    String formattedCloseTime = closeTime != null
        ? DateFormat.yMMMd().add_jm().format(closeTime!)
        : 'N/A';
    print('Formatted CloseTime: $formattedCloseTime');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: AppColors.light, // Dark background color
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: getInterpolatedColor(
                  widget.userRating), // Adjust color as needed
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
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.isHost)
                      IconButton(
                        icon: Icon(Icons.delete,
                            color: getInterpolatedColor(widget.userRating)),
                        onPressed: _confirmDelete,
                      ),
                    Expanded(
                      child: Text(
                        pollData['question'],
                        style: AppColors.titleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.isHost)
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: getInterpolatedColor(widget.userRating)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupEditPollPage(
                                groupID: widget.groupID,
                                pollData: pollData,
                                userRating: widget.userRating,
                                username: widget.username,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.light, // Dark background color
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: getInterpolatedColor(
                          widget.userRating), // Adjust color as needed
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
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: responseWidgets,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Poll responses locked at $formattedCloseTime",
                  style: AppColors.subtitleStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
