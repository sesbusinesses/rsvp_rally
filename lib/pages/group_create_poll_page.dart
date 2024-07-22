import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/group_page_view.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class GroupCreatePollPage extends StatefulWidget {
  final String username;
  final String groupID;
  final double userRating;

  const GroupCreatePollPage(
      {super.key,
      required this.username,
      required this.groupID,
      required this.userRating});

  @override
  GroupCreatePollPageState createState() => GroupCreatePollPageState();
}

class GroupCreatePollPageState extends State<GroupCreatePollPage> {
  final TextEditingController pollQuestionController = TextEditingController();
  List<TextEditingController> optionControllers = [];
  DateTime? selectedDueDate;

  @override
  void initState() {
    super.initState();
    // Add two empty controllers initially for the minimum two options
    optionControllers.add(TextEditingController());
    optionControllers.add(TextEditingController());
    selectedDueDate = DateTime.now().add(const Duration(days: 1));
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

  Future<void> selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  Future<void> createPoll() async {
    if (pollQuestionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter the poll question',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (optionControllers.length < 2 ||
        optionControllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter at least two poll options',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (pollQuestionController.text.contains('/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Poll question cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (optionControllers
        .any((controller) => controller.text.contains('/'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Poll options cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
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
    DateTime dueDate =
        selectedDueDate ?? DateTime.now().add(const Duration(days: 1));
    DateTime dueDateWithTime =
        DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59);
    String pollQuestion = pollQuestionController.text;
    Map<String, dynamic> pollData = {
      'question': pollQuestion,
      'options': options,
      'CloseTime': Timestamp.fromDate(dueDateWithTime),
      'IsClosed': false
    };

    try {
      // Add the new poll to the Polls subcollection
      DocumentReference pollDocRef = firestore
          .collection('Groups')
          .doc(widget.groupID)
          .collection('Polls')
          .doc(pollQuestion);
      await pollDocRef.set(pollData);

      // Fetch the group data to get the members
      DocumentSnapshot groupDoc =
          await firestore.collection('Groups').doc(widget.groupID).get();
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> members = List<String>.from(groupData['members'] ?? []);

      // Create a message for the poll creation
      Timestamp timestamp = Timestamp.now();
      Map<String, dynamic> pollMessage = {
        'text':
            'A new poll "$pollQuestion" has been created for the group "${groupData['Name']}".',
        'type': 'poll reminder',
        'groupID': widget.groupID,
        'timestamp': timestamp
      };

      // Send the message to each member
      WriteBatch batch = firestore.batch();
      for (String member in members) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(member);
        batch.update(userDocRef, {
          'Messages': FieldValue.arrayUnion([pollMessage]),
          'NewMessages': true,
        });
      }

      // Commit the batch
      await batch.commit();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Poll created successfully', style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );

      // Clear inputs
      pollQuestionController.clear();
      setState(() {
        optionControllers.clear();
        optionControllers.add(TextEditingController());
        optionControllers.add(TextEditingController());
      });
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupPageView(
            username: widget.username,
            groupID: widget.groupID,
            userRating: widget.userRating,
          ),
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to create poll: $e', style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Poll', style: AppColors.topStyle),
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
                              backgroundColor: getInterpolatedColor(
                                  widget.userRating), // Adjust color as needed
                            ),
                            child: Text('Add Option',
                                style: AppColors.buttonStyle.copyWith(
                                    color: getTextOnRatingColor(
                                        widget.userRating))),
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
                      child: Column(
                        children: [
                          Text('Poll Due Date', style: AppColors.titleStyle),
                          ElevatedButton(
                            onPressed: () => selectDueDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getInterpolatedColor(
                                  widget.userRating), // Adjust color as needed
                            ),
                            child: Text(
                                selectedDueDate != null
                                    ? DateFormat.yMMMd()
                                        .format(selectedDueDate!)
                                    : 'Select Due Date',
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
              height: 100,
              child: WideButton(
                buttonText: 'Create Poll',
                onPressed: createPoll,
                rating: widget.userRating,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
