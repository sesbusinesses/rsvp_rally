import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
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
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Collect phases
    List<Map<String, dynamic>> phases = phaseControllers.map((controller) {
      return {
        'PhaseName': controller['name']!.text,
        'PhaseLocation': controller['location']!.text,
        'StartTime':
            Timestamp.fromDate(DateTime.parse(controller['startTime']!.text)),
        'EndTime':
            Timestamp.fromDate(DateTime.parse(controller['endTime']!.text)),
      };
    }).toList();

    // Collect notifications
    List<Map<String, dynamic>> notifications =
        notificationControllers.map((controller) {
      return {
        'NotificationText': controller['text']!.text,
        'NotificationTime':
            Timestamp.fromDate(DateTime.parse(controller['time']!.text)),
      };
    }).toList();

    // Create event data
    Map<String, dynamic> eventData = {
      'EventName': eventNameController.text,
      'Details': eventDetailsController.text,
      'HostName': widget.username,
      'Attendees': attendees,
      'Timeline': phases,
      'Notifications': notifications,
    };

    try {
      // Add event to Firestore
      await firestore.collection('Events').add(eventData);

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
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: Colors.transparent,
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
                        border: Border.all(
                            color: getInterpolatedColor(widget.rating)),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: screenSize.width * 0.85,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: getInterpolatedColor(widget.rating)),
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
