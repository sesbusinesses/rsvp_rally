import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class PollCard extends StatefulWidget {
  final String eventID;
  final String username;
  final Map<String, dynamic> pollData;
  final double userRating; // Add userRating parameter

  const PollCard({
    super.key,
    required this.eventID,
    required this.username,
    required this.pollData,
    required this.userRating, // Add userRating parameter
  });

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  late Map<String, dynamic> pollData;

  @override
  void initState() {
    super.initState();
    pollData = widget.pollData;
  }

  Future<void> _vote(String selectedOption) async {
    try {
      DocumentReference eventRef =
          FirebaseFirestore.instance.collection('Events').doc(widget.eventID);
      DocumentSnapshot eventSnapshot = await eventRef.get();
      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;

      Map<String, dynamic> polls =
          Map<String, dynamic>.from(eventData['Polls']);
      Map<String, dynamic> pollResponses =
          Map<String, dynamic>.from(polls[pollData['question']]);

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

      await eventRef.update({'Polls.${pollData['question']}': pollResponses});

      // Update local pollData state
      setState(() {
        pollData['responses'] = pollResponses;
      });
    } catch (e) {
      print('Error voting: $e');
    }
  }

  Future<String?> _fetchProfilePicture(String username) async {
    return await pullProfilePicture(username);
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    List<Widget> responseWidgets = [];

    pollData['responses'].forEach((option, voters) {
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
                    _vote(option);
                  },
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
                        return const CircularProgressIndicator(strokeWidth: 2);
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
    Timestamp closeTime = pollData['responses']['CloseTime'];
    String formattedCloseTime =
        DateFormat.yMMMd().add_jm().format(closeTime.toDate());

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: AppColors.light, // Dark background color
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
                Text(
                  pollData['question'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.light, // Dark background color
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
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: responseWidgets,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Poll responses locked at $formattedCloseTime",
                  style: const TextStyle(
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
