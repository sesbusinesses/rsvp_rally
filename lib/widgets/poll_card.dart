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
  final String pollID;
  final Map<String, dynamic> pollData;
  final double userRating;
  final bool isEssential;

  const PollCard({
    super.key,
    required this.eventID,
    required this.username,
    required this.pollID,
    required this.pollData,
    required this.userRating,
    required this.isEssential,
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
                Text(
                  pollData['Question'],
                  style: AppColors.titleStyle,
                  textAlign: TextAlign.center,
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
