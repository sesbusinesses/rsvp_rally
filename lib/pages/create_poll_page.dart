import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class CreatePollPage extends StatefulWidget {
  final String username;
  final double rating;
  final String eventID;

  const CreatePollPage(
      {super.key,
      required this.username,
      required this.rating,
      required this.eventID});

  @override
  CreatePollPageState createState() => CreatePollPageState();
}

class CreatePollPageState extends State<CreatePollPage> {
  final TextEditingController pollQuestionController = TextEditingController();
  List<TextEditingController> optionControllers = [];

  @override
  void initState() {
    super.initState();
    // Add two empty controllers initially for the minimum two options
    optionControllers.add(TextEditingController());
    optionControllers.add(TextEditingController());
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

  Future<void> createPoll() async {
    if (pollQuestionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the poll question')),
      );
      return;
    } else if (optionControllers.length < 2 ||
        optionControllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least two poll options')),
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
      ...options,
      'CloseTime':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)))
    };

    try {
      // Update event document with the new poll
      DocumentReference eventDocRef =
          firestore.collection('Events').doc(widget.eventID);
      await eventDocRef.update({'Polls.$pollQuestion': pollData});

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully')),
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
          builder: (context) => PollPage(
            username: widget.username,
            rating: widget.rating,
            eventID: widget.eventID,
          ),
        ),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create poll: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Poll'),
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
                          color: getInterpolatedColor(widget.rating),
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
                          const Text('Poll Question',
                              style: TextStyle(fontSize: 20)),
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
                          color: getInterpolatedColor(widget.rating),
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
                          const Text('Poll Options',
                              style: TextStyle(fontSize: 20)),
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
                                  getInterpolatedColor(widget.rating),
                            ),
                            child: const Text('Add Option',
                                style: TextStyle(color: AppColors.dark)),
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
                rating: widget.rating,
                buttonText: 'Create Poll',
                onPressed: createPoll,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
