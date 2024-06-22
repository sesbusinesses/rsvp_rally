// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/phases_section.dart';
import 'package:rsvp_rally/widgets/notifications_section.dart';

class CreateEventPage extends StatefulWidget {
  final String username;
  final double rating;

  const CreateEventPage(
      {super.key, required this.username, required this.rating});

  @override
  CreateEventPageState createState() => CreateEventPageState();
}

class CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDetailsController = TextEditingController();
  List<Map<String, TextEditingController>> phaseControllers = [];
  List<Map<String, TextEditingController>> notificationControllers = [];
  List<String> attendees = [];

  void addPhase() {
    setState(() {
      phaseControllers.add({
        'name': TextEditingController(),
        'location': TextEditingController(),
        'startTime': TextEditingController(),
        'endTime': TextEditingController(),
      });
    });
  }

  void removePhase(int index) {
    setState(() {
      phaseControllers[index]['name']?.dispose();
      phaseControllers[index]['location']?.dispose();
      phaseControllers[index]['startTime']?.dispose();
      phaseControllers[index]['endTime']?.dispose();
      phaseControllers.removeAt(index);
    });
  }

  void addNotification() {
    setState(() {
      notificationControllers.add({
        'text': TextEditingController(),
        'time': TextEditingController(),
      });
    });
  }

  void removeNotification(int index) {
    setState(() {
      notificationControllers[index]['text']?.dispose();
      notificationControllers[index]['time']?.dispose();
      notificationControllers.removeAt(index);
    });
  }

  Future<void> createEvent() async {
    if (eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the event name')),
      );
      return;
    } else if (eventDetailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the event details')),
      );
      return;
    } else if (attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please invite at least one person')),
      );
      return;
    } else if (phaseControllers.any((controller) =>
        controller['name']!.text.isEmpty ||
        controller['location']!.text.isEmpty ||
        controller['startTime']!.text.isEmpty ||
        controller['endTime']!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all phase details')),
      );
      return;
    } else if (notificationControllers.any((controller) =>
        controller['text']!.text.isEmpty || controller['time']!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill out all notification details')),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch host's first name and last name
    DocumentSnapshot hostDoc =
        await firestore.collection('Users').doc(widget.username).get();
    String hostFirstName = hostDoc['FirstName'] ?? widget.username;
    String hostLastName = hostDoc['LastName'] ?? '';

    // Collect phases
    List<Map<String, dynamic>> phases = phaseControllers.map((controller) {
      DateTime? startTime;
      DateTime? endTime;
      try {
        startTime = DateTime.parse(controller['startTime']!.text);
      } catch (e) {
        startTime = null; // Handle invalid start time format
      }
      try {
        endTime = DateTime.parse(controller['endTime']!.text);
      } catch (e) {
        endTime = null; // Handle invalid end time format
      }

      return {
        'PhaseName': controller['name']!.text,
        'PhaseLocation': controller['location']!.text,
        'StartTime': startTime != null ? Timestamp.fromDate(startTime) : null,
        'EndTime': endTime != null ? Timestamp.fromDate(endTime) : null,
      };
    }).toList();

    // Collect notifications
    List<Map<String, dynamic>> notifications =
        notificationControllers.map((controller) {
      DateTime? notificationTime;
      try {
        notificationTime = DateTime.parse(controller['time']!.text);
      } catch (e) {
        notificationTime = null; // Handle invalid notification time format
      }

      return {
        'NotificationText': controller['text']!.text,
        'NotificationTime': notificationTime != null
            ? Timestamp.fromDate(notificationTime)
            : null,
      };
    }).toList();

    // Create polls for each phase
    Map<String, dynamic> polls = {};
    for (var phase in phases) {
      String pollQuestion = 'RSVP for ${phase['PhaseName']}';
      polls[pollQuestion] = {
        'Yes': [],
        'No': [],
        'CloseTime': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1))), // Example close time
        'IsAlarmSet': false,
      };
    }

    // Create event data
    Map<String, dynamic> eventData = {
      'EventName': eventNameController.text,
      'Details': eventDetailsController.text,
      'HostName': widget.username,
      'Attendees': attendees,
      'Timeline': phases,
      'Notifications': notifications,
      'Polls': polls,
    };

    try {
      // Add event to Firestore
      DocumentReference eventDocRef =
          await firestore.collection('Events').add(eventData);
      String eventID = eventDocRef.id;

      // Create timestamp
      Timestamp timestamp = Timestamp.now();

      // Add the event ID to the 'Events' field for the host and each attendee
      WriteBatch batch = firestore.batch();

      // Add event to host
      DocumentReference hostDocRef =
          firestore.collection('Users').doc(widget.username);
      batch.update(hostDocRef, {
        'Events': FieldValue.arrayUnion([eventID]),
        'Messages': FieldValue.arrayUnion([
          {
            'text': 'You\'ve successfully created ${eventNameController.text}.',
            'type': 'event created',
            'timestamp': timestamp
          }
        ]),
        'NewMessages': true,
      });

      // Add event to attendees
      for (String attendee in attendees) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(attendee);
        batch.update(userDocRef, {
          'Events': FieldValue.arrayUnion([eventID]),
          'Messages': FieldValue.arrayUnion([
            {
              'text':
                  '$hostFirstName $hostLastName has invited you to ${eventNameController.text}. You have 24 hours to RSVP!',
              'type': 'event invitation',
              'eventID': eventID,
              'timestamp': timestamp
            }
          ]),
          'NewMessages': true,
        });
      }

      // Commit the batch
      await batch.commit();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );

      // Clear inputs
      eventNameController.clear();
      eventDetailsController.clear();
      setState(() {
        phaseControllers.clear();
        notificationControllers.clear();
        attendees.clear();
      });

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return EventPage(
          username: widget.username,
        );
      }));
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Create New Event'),
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
                        color: AppColors.light, // Dark background color
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
                          const Text('Event Name',
                              style: TextStyle(fontSize: 20)),
                          WideTextBox(
                            hintText: 'Event Name',
                            controller: eventNameController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    PhasesSection(
                      rating: widget.rating,
                      phaseControllers: phaseControllers,
                      onAddPhase: addPhase,
                      onRemovePhase: removePhase,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: screenSize.width * 0.05),
                      width: screenSize.width * 0.95,
                      decoration: BoxDecoration(
                        color: AppColors.light, // Dark background color
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
                          const Text('Additional Details',
                              style: TextStyle(fontSize: 20)),
                          WideTextBox(
                            hintText: 'Event Details',
                            controller: eventDetailsController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    NotificationsSection(
                      rating: widget.rating,
                      notificationControllers: notificationControllers,
                      onAddNotification: addNotification,
                      onRemoveNotification: removeNotification,
                    ),
                    const SizedBox(height: 10),
                    AttendeeEntrySection(
                      rating: widget.rating,
                      username: widget.username,
                      onAttendeesChanged: (newAttendees) {
                        setState(() {
                          attendees = newAttendees;
                        });
                      },
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
                buttonText: 'Create Event',
                onPressed: createEvent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
