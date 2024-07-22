import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/group_page_view.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class GroupEditPollPage extends StatefulWidget {
  final String groupID;
  final Map<String, dynamic> pollData;
  final String username;
  final double userRating;

  const GroupEditPollPage({
    super.key,
    required this.groupID,
    required this.pollData,
    required this.username,
    required this.userRating,
  });

  @override
  GroupEditPollPageState createState() => GroupEditPollPageState();
}

class GroupEditPollPageState extends State<GroupEditPollPage> {
  final TextEditingController pollQuestionController = TextEditingController();
  List<TextEditingController> optionControllers = [];

  @override
  void initState() {
    super.initState();
    // Populate the controllers with existing poll data
    pollQuestionController.text = widget.pollData['question'];
    widget.pollData['responses']['options'].forEach((option, voters) {
      optionControllers.add(TextEditingController(text: option));
    });
  }

  void addOption() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  void removeOption(int index) {
    setState(() {
      optionControllers[index].dispose();
      optionControllers.removeAt(index);
    });
  }

  Future<void> updatePoll() async {
    if (pollQuestionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the poll question',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    } else if (optionControllers.length < 2 ||
        optionControllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least two poll options',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Collect options
    Map<String, List<String>> options = {};
    for (var controller in optionControllers) {
      options[controller.text] = [];
    }

    // Create poll data
    String pollQuestion = pollQuestionController.text;
    Map<String, dynamic> pollData = {
      'question': pollQuestion,
      'options': options,
      'CloseTime': widget.pollData['CloseTime'],
      'IsClosed': widget.pollData['responses']['IsClosed']
    };

    try {
      // Update group document with the updated poll
      await firestore
          .collection('Groups')
          .doc(widget.groupID)
          .collection('Polls')
          .doc(widget.pollData['question'])
          .update({
        'question': pollQuestion,
        'options': options,
        'CloseTime': widget.pollData['CloseTime'],
        'IsClosed': widget.pollData['responses']['IsClosed']
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Poll updated successfully', style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupPageView(
            groupID: widget.groupID,
            username: widget.username,
            userRating: widget.userRating,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update poll: $e', style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Poll', style: AppColors.topStyle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                bottom: 70), // Add bottom padding to avoid overlap
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: screenSize.width * 0.05),
                      width: screenSize.width * 0.95,
                      decoration: BoxDecoration(
                        color: AppColors.light, // Light background color
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
                      child: Column(
                        children: [
                          Text('Poll Question', style: AppColors.titleStyle),
                          WideTextBox(
                            hintText: 'Poll Question',
                            controller: pollQuestionController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: screenSize.width * 0.05),
                      width: screenSize.width * 0.95,
                      decoration: BoxDecoration(
                        color: AppColors.light, // Light background color
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
                      child: Column(
                        children: [
                          Text('Poll Options', style: AppColors.titleStyle),
                          ...List.generate(optionControllers.length, (index) {
                            return Row(
                              children: [
                                Expanded(
                                  child: WideTextBox(
                                    hintText: 'Option ${index + 1}',
                                    controller: optionControllers[index],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () => removeOption(index),
                                ),
                              ],
                            );
                          }),
                          ElevatedButton(
                            onPressed: addOption,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  getInterpolatedColor(widget.userRating),
                            ),
                            child: Text('Add Option',
                                style: AppColors.buttonStyle.copyWith(
                                    color: getTextOnRatingColor(
                                        widget.userRating))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                        height:
                            80), // Add some space at the bottom for better visibility
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 110,
              child: WideButton(
                buttonText: 'Update Poll',
                onPressed: updatePoll,
                rating: widget.userRating,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
