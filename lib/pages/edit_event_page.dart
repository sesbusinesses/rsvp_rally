import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/phases_section.dart';
import 'package:rsvp_rally/widgets/notifications_section.dart';

class EditEventPage extends StatefulWidget {
  final String username;
  final String eventID;

  const EditEventPage(
      {super.key, required this.username, required this.eventID});

  @override
  EditEventPageState createState() => EditEventPageState();
}

class EditEventPageState extends State<EditEventPage> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDetailsController = TextEditingController();
  List<Map<String, TextEditingController>> phaseControllers = [];
  List<Map<String, TextEditingController>> notificationControllers = [];

  @override
  void initState() {
    super.initState();
    loadEventData();
  }

  void loadEventData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(widget.eventID).get();

    if (eventDoc.exists) {
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

      log("Raw Event Document: $eventData");

      eventNameController.text = eventData['EventName'] ?? "";
      eventDetailsController.text = eventData['Details'] ?? "";

      List<dynamic> phases = eventData['Timeline'] ?? [];
      List<dynamic> notifications = eventData['Notifications'] ?? [];

      phaseControllers.clear();
      notificationControllers.clear();

      for (var phase in phases) {
        phaseControllers.add({
          'name': TextEditingController(text: phase['PhaseName']),
          'location': TextEditingController(text: phase['PhaseLocation']),
          'startTime':
              TextEditingController(text: _formatTimestamp(phase['StartTime'])),
          'endTime':
              TextEditingController(text: _formatTimestamp(phase['EndTime'])),
        });
      }

      for (var notification in notifications) {
        notificationControllers.add({
          'text': TextEditingController(text: notification['NotificationText']),
          'time': TextEditingController(
              text: _formatTimestamp(notification['NotificationTime'])),
        });
      }

      log("Loaded Event Name: ${eventNameController.text}");
      log("Loaded Event Details: ${eventDetailsController.text}");
      log("Loaded Phases: ${phaseControllers.map((pc) => pc.map((key, value) => MapEntry(key, value.text)))}");
      log("Loaded Notifications: ${notificationControllers.map((nc) => nc.map((key, value) => MapEntry(key, value.text)))}");

      setState(() {}); // Update the UI with the loaded data
    } else {
      log("No event found with ID ${widget.eventID}");
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        width: screenSize.width * 0.85,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Event Name',
                                style: TextStyle(fontSize: 20)),
                            WideTextBox(
                              hintText: 'Event Name',
                              controller: eventNameController,
                            ),
                          ],
                        )),
                    const SizedBox(height: 10),
                    PhasesSection(
                      phaseControllers: phaseControllers,
                      onAddPhase: () {
                        setState(() {
                          phaseControllers.add({
                            'name': TextEditingController(),
                            'location': TextEditingController(),
                            'startTime': TextEditingController(),
                            'endTime': TextEditingController(),
                          });
                        });
                      },
                      onRemovePhase: (index) {
                        setState(() {
                          phaseControllers.removeAt(index);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        width: screenSize.width * 0.85,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Additional Details',
                                style: TextStyle(fontSize: 20)),
                            WideTextBox(
                              hintText: 'Event Details',
                              controller: eventDetailsController,
                            ),
                          ],
                        )),
                    const SizedBox(height: 10),
                    NotificationsSection(
                      notificationControllers: notificationControllers,
                      onAddNotification: () {
                        setState(() {
                          notificationControllers.add({
                            'text': TextEditingController(),
                            'time': TextEditingController(),
                          });
                        });
                      },
                      onRemoveNotification: (index) {
                        setState(() {
                          notificationControllers.removeAt(index);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    AttendeeEntrySection(username: widget.username),
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
                buttonText: 'Update Event',
                onPressed: () {
                  // Implement event update logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
