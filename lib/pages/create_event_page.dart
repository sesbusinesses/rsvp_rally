import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/phases_section.dart';
import 'package:rsvp_rally/widgets/notifications_section.dart';

// ignore: must_be_immutable
class CreateEventPage extends StatefulWidget {
  String username;

  CreateEventPage({super.key, required this.username});

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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            WideTextBox(
                hintText: 'Event Name', controller: eventNameController),
            const SizedBox(height: 10),
            PhasesSection(
              phaseControllers: phaseControllers,
              onAddPhase: addPhase,
              onRemovePhase: removePhase, // Pass the correct remove callback
            ),
            const SizedBox(height: 10),
            NotificationsSection(
              notificationControllers: notificationControllers,
              onAddNotification: addNotification,
              onRemoveNotification:
                  removeNotification, // Pass the correct remove callback
            ),
            const SizedBox(height: 10),
            AttendeeEntrySection(username: widget.username),
            const SizedBox(height: 10),
            WideTextBox(
                hintText: 'Event Details', controller: eventDetailsController),
            const SizedBox(height: 10),
            WideButton(buttonText: 'Create Event', onPressed: () {})
          ],
        ),
      ),
    );
  }
}
