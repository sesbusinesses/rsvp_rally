import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page_view.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class EditPollPage extends StatefulWidget {
  final String eventID;
  final String pollID;
  final Map<String, dynamic> pollData;
  final bool isEssential;
  final double userRating;
  final String username;

  const EditPollPage({
    super.key,
    required this.eventID,
    required this.pollID,
    required this.pollData,
    required this.isEssential,
    required this.userRating,
    required this.username,
  });

  @override
  EditPollPageState createState() => EditPollPageState();
}

class EditPollPageState extends State<EditPollPage> {
  late TextEditingController pollQuestionController;
  late List<TextEditingController> optionControllers;
  late List<String> originalOptions;
  late DateTime closeTime;

  @override
  void initState() {
    super.initState();
    pollQuestionController =
        TextEditingController(text: widget.pollData['Question'] ?? '');

    // Ensure pollData contains the options directly
    print('Poll Data in initState: ${widget.pollData}'); // Debug print

    optionControllers = widget.pollData.keys
        .where((key) =>
            key != 'Question' && key != 'CloseTime' && key != 'IsClosed')
        .map<TextEditingController>((option) {
      return TextEditingController(text: option);
    }).toList();

    originalOptions = widget.pollData.keys
        .where((key) =>
            key != 'Question' && key != 'CloseTime' && key != 'IsClosed')
        .toList();

    print('Initialized optionControllers: $optionControllers'); // Debug print

    closeTime = (widget.pollData['CloseTime'] as Timestamp?)?.toDate() ??
        DateTime.now();
    print('Initialized closeTime: $closeTime'); // Debug print
  }

  Future<void> selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: closeTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != closeTime) {
      setState(() {
        closeTime = picked.add(const Duration(hours: 23, minutes: 59));
      });
    }
  }

  Future<void> updatePoll() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference pollRef = firestore
        .collection('Events')
        .doc(widget.eventID)
        .collection(widget.isEssential ? 'EssentialPolls' : 'NonessentialPolls')
        .doc(widget.pollID);

    Map<String, dynamic> updatedPollData = {
      'CloseTime': Timestamp.fromDate(closeTime),
    };

    if (!widget.isEssential) {
      updatedPollData['Question'] = pollQuestionController.text;

      // Update the options correctly by maintaining the previous data
      for (var controller in optionControllers) {
        String newOptionName = controller.text;
        if (originalOptions.contains(newOptionName)) {
          updatedPollData[newOptionName] = widget.pollData[newOptionName] ?? [];
        } else {
          updatedPollData[newOptionName] = [];
        }
      }

      // Ensure removed options are deleted
      for (var option in originalOptions) {
        if (!updatedPollData.containsKey(option)) {
          updatedPollData[option] = FieldValue.delete();
        }
      }

      print('Updated poll data: $updatedPollData'); // Debug print
    }

    await pollRef.update(updatedPollData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Poll updated successfully', style: AppColors.bodyStyle),
        backgroundColor: AppColors.accentLight,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventPageView(
          username: widget.username,
          rating: widget.userRating,
          eventID: widget.eventID,
        ),
      ),
    );
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
            padding: const EdgeInsets.only(bottom: 70),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!widget.isEssential)
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: screenSize.width * 0.05),
                        width: screenSize.width * 0.95,
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
                    if (!widget.isEssential)
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: screenSize.width * 0.05),
                        width: screenSize.width * 0.95,
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
                                    onPressed: () => setState(() {
                                      optionControllers[index].dispose();
                                      optionControllers.removeAt(index);
                                    }),
                                  ),
                                ],
                              );
                            }),
                            ElevatedButton(
                              onPressed: () => setState(() {
                                optionControllers.add(TextEditingController());
                              }),
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
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: screenSize.width * 0.05),
                      width: screenSize.width * 0.95,
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
                      child: Column(
                        children: [
                          Text('Poll Due Date', style: AppColors.titleStyle),
                          ElevatedButton(
                            onPressed: () => selectDueDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  getInterpolatedColor(widget.userRating),
                            ),
                            child: Text(DateFormat.yMMMd().format(closeTime),
                                style: AppColors.buttonStyle.copyWith(
                                    color: getTextOnRatingColor(
                                        widget.userRating))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    WideButton(
                      buttonText: 'Update Poll',
                      onPressed: updatePoll,
                      rating: widget.userRating,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
