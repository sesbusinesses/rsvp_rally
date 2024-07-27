import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/pages/edit_poll_page.dart';

class PollCard extends StatefulWidget {
  final String eventID;
  final String username;
  final String pollID;
  final Map<String, dynamic> pollData;
  final double userRating;
  final bool isEssential;
  final bool isHost;

  const PollCard({
    super.key,
    required this.eventID,
    required this.username,
    required this.pollID,
    required this.pollData,
    required this.userRating,
    required this.isEssential,
    required this.isHost,
  });

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  late Map<String, dynamic> pollData;
  late DateTime closeTime;

  @override
  void initState() {
    super.initState();
    pollData = widget.pollData;
    closeTime = (pollData['CloseTime'] as Timestamp).toDate();
  }

  Future<void> _vote(String selectedOption) async {
    try {
      DocumentReference pollRef = FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .collection(
              widget.isEssential ? 'EssentialPolls' : 'NonessentialPolls')
          .doc(widget.pollID);

      DocumentSnapshot pollSnapshot = await pollRef.get();
      if (pollSnapshot.exists) {
        Map<String, dynamic>? pollResponses =
            pollSnapshot.data() as Map<String, dynamic>?;

        if (pollResponses != null) {
          // Remove user from all other options
          pollResponses.forEach((option, voters) {
            if (voters is List<dynamic>) {
              voters.remove(widget.username);
            }
          });

          // Add user to the selected option
          List<dynamic> selectedVoters = pollResponses[selectedOption] ?? [];
          if (!selectedVoters.contains(widget.username)) {
            selectedVoters.add(widget.username);
            pollResponses[selectedOption] = selectedVoters;
          }

          await pollRef.update(pollResponses);

          // Update local pollData state
          setState(() {
            pollData = pollResponses;
          });
        } else {
          print('Poll data is null');
        }
      } else {
        print('Poll document does not exist');
      }
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
    if (widget.isEssential) return; // Essential polls can't be deleted

    try {
      DocumentReference pollRef = FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .collection('NonessentialPolls')
          .doc(widget.pollID);

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

    pollData.forEach((option, voters) {
      if (voters is List<dynamic>) {
        List<String> voterNames = List<String>.from(voters);

        responseWidgets.add(
          Column(
            children: [
              SizedBox(
                width: screenSize.width * 0.7225,
                child: WideButton(
                  buttonText: option,
                  rating: widget.userRating,
                  onPressed: () {
                    if (DateTime.now().isBefore(closeTime)) {
                      _vote(option);
                    }
                  },
                  smallVersion: true,
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
                          runSpacing: 4.0,
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
    String formattedCloseTime = DateFormat.yMMMd().add_jm().format(closeTime);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: getInterpolatedColor(widget.userRating),
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
                    if (!widget.isEssential && widget.isHost)
                      IconButton(
                        icon: Icon(Icons.delete,
                            color: getInterpolatedColor(widget.userRating)),
                        onPressed: () {
                          _confirmDelete();
                        },
                      ),
                    Expanded(
                      child: Text(
                        pollData['Question'],
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
                              builder: (context) => EditPollPage(
                                username: widget.username,
                                eventID: widget.eventID,
                                pollID: widget.pollID,
                                pollData: pollData,
                                isEssential: widget.isEssential,
                                userRating: widget.userRating,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: responseWidgets,
                  ),
                ),
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
