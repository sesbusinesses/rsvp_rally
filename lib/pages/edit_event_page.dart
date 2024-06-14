// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/phases_section.dart';
import 'package:rsvp_rally/widgets/notifications_section.dart';

class EditEventPage extends StatefulWidget {
  final String eventID;
  final String username;
  final double rating;

  const EditEventPage({
    super.key,
    required this.eventID,
    required this.username,
    required this.rating,
  });

  @override
  EditEventPageState createState() => EditEventPageState();
}

class EditEventPageState extends State<EditEventPage> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDetailsController = TextEditingController();
  List<Map<String, TextEditingController>> phaseControllers = [];
  List<Map<String, TextEditingController>> notificationControllers = [];
  List<String> attendees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEventData();
  }

  Future<void> loadEventData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventSnapshot =
        await firestore.collection('Events').doc(widget.eventID).get();

    if (eventSnapshot.exists) {
      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;

      setState(() {
        eventNameController.text = eventData['EventName'] ?? '';
        eventDetailsController.text = eventData['Details'] ?? '';
        attendees = List<String>.from(eventData['Attendees'] ?? []);

        phaseControllers = (eventData['Timeline'] as List<dynamic>?)
                ?.map((phase) {
              return {
                'name': TextEditingController(text: phase['PhaseName'] ?? ''),
                'location':
                    TextEditingController(text: phase['PhaseLocation'] ?? ''),
                'startTime': TextEditingController(
                    text: phase['StartTime'] != null
                        ? (phase['StartTime'] as Timestamp).toDate().toString()
                        : ''),
                'endTime': TextEditingController(
                    text: phase['EndTime'] != null
                        ? (phase['EndTime'] as Timestamp).toDate().toString()
                        : ''),
              };
            }).toList() ??
            [];

        notificationControllers =
            (eventData['Notifications'] as List<dynamic>?)?.map((notification) {
                  return {
                    'text': TextEditingController(
                        text: notification['NotificationText'] ?? ''),
                    'time': TextEditingController(
                        text: notification['NotificationTime'] != null
                            ? (notification['NotificationTime'] as Timestamp)
                                .toDate()
                                .toString()
                            : ''),
                  };
                }).toList() ??
                [];

        isLoading = false;
      });
    }
  }

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

  Future<void> updateEvent() async {
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

    // Update event data
    Map<String, dynamic> eventData = {
      'EventName': eventNameController.text,
      'Details': eventDetailsController.text,
      'HostName': widget.username,
      'Attendees': attendees,
      'Timeline': phases,
      'Notifications': notifications,
    };

    try {
      // Update event in Firestore
      await firestore
          .collection('Events')
          .doc(widget.eventID)
          .update(eventData);

      // Add the event ID to the 'Events' field for the host and each attendee
      WriteBatch batch = firestore.batch();

      // Add event to host
      DocumentReference hostDocRef =
          firestore.collection('Users').doc(widget.username);
      batch.update(hostDocRef, {
        'Events': FieldValue.arrayUnion([widget.eventID])
      });

      // Add event to attendees
      for (String attendee in attendees) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(attendee);
        batch.update(userDocRef, {
          'Events': FieldValue.arrayUnion([widget.eventID])
        });
      }

      // Commit the batch
      await batch.commit();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event: $e')),
      );
    }
  }

  Future<void> deleteEvent(String eventID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch host's first name and last name
    DocumentSnapshot hostDoc =
        await firestore.collection('Users').doc(widget.username).get();
    String hostFirstName = hostDoc['FirstName'] ?? widget.username;
    String hostLastName = hostDoc['LastName'] ?? '';

    try {
      // Get the event document
      DocumentSnapshot eventDoc =
          await firestore.collection('Events').doc(eventID).get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        List<dynamic> attendees = eventData['Attendees'] ?? [];

        WriteBatch batch = firestore.batch();

        // Remove the event ID from each attendee's event list
        for (String attendee in attendees) {
          DocumentReference userDocRef =
              firestore.collection('Users').doc(attendee);
          batch.update(userDocRef, {
            'Events': FieldValue.arrayRemove([eventID]),
            'Messages': FieldValue.arrayUnion([
              {
                'text':
                    '$hostFirstName $hostLastName has cancelled ${eventData['EventName']}.',
                'type': 'event cancelled',
                'eventID': eventID,
              }
            ]),
            'NewMessages': true,
          });
        }

        // Remove the event ID from the host's event list
        String hostName = eventData['HostName'];
        DocumentReference hostDocRef =
            firestore.collection('Users').doc(hostName);
        batch.update(hostDocRef, {
          'Events': FieldValue.arrayRemove([eventID]),
          'Messages': FieldValue.arrayUnion([
            {
              'text': 'You have deleted event ${eventData['EventName']}.',
              'type': 'event cancelled',
              'eventID': eventID,
            }
          ]),
          'NewMessages': true,
        });

        // Delete the event document
        DocumentReference eventDocRef =
            firestore.collection('Events').doc(eventID);
        batch.delete(eventDocRef);

        // Commit the batch operation
        await batch.commit();

        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventPage(username: widget.username),
          ),
        );

        print('Event deleted successfully.');
      } else {
        print('Event not found.');
      }
    } catch (e) {
      print('Failed to delete event: $e');
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      bottom: 120), // Padding for BottomNav
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: screenSize.width * 0.05),
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
                                vertical: 10,
                                horizontal: screenSize.width * 0.05),
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
                            existingAttendees: attendees,
                          ),
                          const SizedBox(
                              height: 10), // Add spacing before the button
                          WideButton(
                            rating: widget.rating,
                            buttonText: 'Update Event',
                            onPressed: updateEvent,
                          ),
                          const SizedBox(height: 10),
                          WideButton(
                            rating: widget.rating,
                            buttonText: 'Delete Event',
                            onPressed: () async {
                              await deleteEvent(widget.eventID);
                            },
                          ),
                          const SizedBox(
                              height: 120), // Adjusted space at the bottom
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: BottomNav(
                    rating: widget.rating,
                    eventID: widget.eventID,
                    username: widget.username,
                    selectedIndex: 3, // Index for EditEventPage
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    eventNameController.dispose();
    eventDetailsController.dispose();
    for (var controller in phaseControllers) {
      controller['name']?.dispose();
      controller['location']?.dispose();
      controller['startTime']?.dispose();
      controller['endTime']?.dispose();
    }
    for (var controller in notificationControllers) {
      controller['text']?.dispose();
      controller['time']?.dispose();
    }
    super.dispose();
  }
}
