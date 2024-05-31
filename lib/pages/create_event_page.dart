import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/phases_section.dart';
import 'package:rsvp_rally/widgets/notifications_section.dart';

class CreateEventPage extends StatefulWidget {
  final String username;

  const CreateEventPage({super.key, required this.username});

  @override
  CreateEventPageState createState() => CreateEventPageState();
}

class CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDetailsController = TextEditingController();
  List<Map<String, TextEditingController>> phaseControllers = [];
  List<Map<String, TextEditingController>> notificationControllers = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFfefdfd),
              Color(0xFF5f42b2)
            ], // White to purple gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom: 70), // Add bottom padding to avoid overlap
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  children: [
                    WideTextBox(
                      hintText: 'Event Name',
                      controller: eventNameController,
                    ),
                    const SizedBox(height: 10),
                    PhasesSection(
                      phaseControllers: phaseControllers,
                      onAddPhase: addPhase,
                      onRemovePhase: removePhase,
                    ),
                    const SizedBox(height: 10),
                    NotificationsSection(
                      notificationControllers: notificationControllers,
                      onAddNotification: addNotification,
                      onRemoveNotification: removeNotification,
                    ),
                    const SizedBox(height: 10),
                    AttendeeEntrySection(username: widget.username),
                    const SizedBox(height: 10),
                    WideTextBox(
                      hintText: 'Event Details',
                      controller: eventDetailsController,
                    ),
                    const SizedBox(
                        height:
                            80), // Add some space at the bottom for better visibility
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 100,
                child: WideButton(
                  buttonText: 'Create Event',
                  onPressed: () {
                    // Implement event creation logic
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
