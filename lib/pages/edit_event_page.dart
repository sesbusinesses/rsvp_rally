import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/attendee_entry_section.dart';
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
  List<Map<String, dynamic>> phaseControllers = [];
  List<Map<String, double>> phaseGeopoints = [];
  List<Map<String, TextEditingController>> notificationControllers = [];
  Map<String, String> attendees = {};
  Map<String, String> originalAttendees = {};
  bool isLoading = true;
  final dateFormat = DateFormat('MMM d, yyyy h:mm a');

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
        attendees = Map<String, String>.from(eventData['Attendees'] ?? {});
        originalAttendees = Map<String, String>.from(attendees);

        phaseControllers = (eventData['Timeline'] as List<dynamic>?)
                ?.map((phase) {
              GeoPoint? geoPoint = phase['PhaseGeopoint'];
              Map<String, double>? geopointMap;
              if (geoPoint != null) {
                geopointMap = {
                  'lat': geoPoint.latitude,
                  'lng': geoPoint.longitude,
                };
              }
              return {
                'name': TextEditingController(text: phase['PhaseName'] ?? ''),
                'location':
                    TextEditingController(text: phase['PhaseLocation'] ?? ''),
                'startTime': TextEditingController(
                    text: phase['StartTime'] != null
                        ? dateFormat
                            .format((phase['StartTime'] as Timestamp).toDate())
                        : ''),
                'endTime': TextEditingController(
                    text: phase['EndTime'] != null
                        ? dateFormat
                            .format((phase['EndTime'] as Timestamp).toDate())
                        : ''),
                'geopoint': geopointMap,
              };
            }).toList() ??
            [];

// Initialize phaseGeopoints to an empty list
        phaseGeopoints = [];

        phaseControllers = (eventData['Timeline'] as List<dynamic>?)
                ?.map((phase) {
              GeoPoint? geoPoint = phase['PhaseGeopoint'];
              Map<String, double>? geopointMap;
              if (geoPoint != null) {
                geopointMap = {
                  'lat': geoPoint.latitude,
                  'lng': geoPoint.longitude,
                };
              }

              // Add the geopoint to phaseGeopoints
              phaseGeopoints.add(geopointMap ?? {});

              return {
                'name': TextEditingController(text: phase['PhaseName'] ?? ''),
                'location':
                    TextEditingController(text: phase['PhaseLocation'] ?? ''),
                'startTime': TextEditingController(
                    text: phase['StartTime'] != null
                        ? dateFormat
                            .format((phase['StartTime'] as Timestamp).toDate())
                        : ''),
                'endTime': TextEditingController(
                    text: phase['EndTime'] != null
                        ? dateFormat
                            .format((phase['EndTime'] as Timestamp).toDate())
                        : ''),
                'geopoint': geopointMap,
              };
            }).toList() ??
            [];

        notificationControllers =
            (eventData['Notifications'] as List<dynamic>?)?.map((notification) {
                  return {
                    'text': TextEditingController(
                        text: notification['NotificationMessage'] ?? ''),
                    'time': TextEditingController(
                        text: notification['NotificationTime'] != null
                            ? dateFormat.format(
                                (notification['NotificationTime'] as Timestamp)
                                    .toDate())
                            : ''),
                  };
                }).toList() ??
                [];

        isLoading = false;
      });
    }
  }

  // Function to parse DateTime from display format
  DateTime? parseDateTimeFromController(TextEditingController controller) {
    try {
      return dateFormat.parse(controller.text);
    } catch (e) {
      print(e);
      return null; // Handle invalid date format
    }
  }

  void addPhase() {
    setState(() {
      phaseControllers.add({
        'name': TextEditingController(),
        'location': TextEditingController(),
        'startTime': TextEditingController(),
        'endTime': TextEditingController(),
        'geopoint': null,
      });
      phaseGeopoints.add({});
    });
  }

  void removePhase(int index) {
    if (index >= 0 && index < phaseControllers.length) {
      setState(() {
        phaseControllers[index]['name']?.dispose();
        phaseControllers[index]['location']?.dispose();
        phaseControllers[index]['startTime']?.dispose();
        phaseControllers[index]['endTime']?.dispose();
        phaseControllers.removeAt(index);
        phaseGeopoints.removeAt(index);
      });
    }
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
    if (index >= 0 && index < notificationControllers.length) {
      setState(() {
        notificationControllers[index]['text']?.dispose();
        notificationControllers[index]['time']?.dispose();
        notificationControllers.removeAt(index);
      });
    }
  }

  Future<void> updateEvent() async {
    if (eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter the event name', style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    } else if (eventDetailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the event details',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    } else if (attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please invite at least one person',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    } else if (phaseControllers.any((controller) =>
        controller['name']!.text.isEmpty ||
        controller['location']!.text.isEmpty ||
        controller['startTime']!.text.isEmpty ||
        (controller['endTime']!.text.isEmpty &&
            controller == phaseControllers.last))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill out all phase details',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (notificationControllers.any((controller) =>
        controller['text']!.text.isEmpty || controller['time']!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill in all notification details',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (eventNameController.text.contains('/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Event name cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (eventDetailsController.text.contains('/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Event details cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (phaseControllers.any((controller) =>
        controller['name']!.text.contains('/') ||
        controller['location']!.text.contains('/'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Phase name or location cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    } else if (notificationControllers
        .any((controller) => controller['text']!.text.contains('/'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Notification text cannot contain "/"',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Collect phases
    List<Map<String, dynamic>> phases = [];

    for (int i = 0; i < phaseControllers.length; i++) {
      DateTime? startTime =
          parseDateTimeFromController(phaseControllers[i]['startTime']!);
      DateTime? endTime =
          parseDateTimeFromController(phaseControllers[i]['endTime']!);

      // If endTime is null and it's not the last phase, set it to the startTime of the next phase
      if (i < phaseControllers.length - 1) {
        endTime =
            parseDateTimeFromController(phaseControllers[i + 1]['startTime']!);
      }

      DocumentSnapshot initialEventDoc =
          await firestore.collection('Events').doc(widget.eventID).get();
      Map<String, dynamic> initialEventData =
          initialEventDoc.data() as Map<String, dynamic>;
      List<dynamic> existingTimeline = initialEventData['Timeline'] ?? [];

      // Determine if the location is still the placeholder
      String locationText = phaseControllers[i]['location']!.text;
      GeoPoint? geopoint;

      // Use the existing GeoPoint if the placeholder is still in use
      if (i < existingTimeline.length &&
          existingTimeline[i]['GeoPoint'] != null) {
        geopoint = existingTimeline[i]['GeoPoint'] as GeoPoint;
        print(
            'Phase ${i + 1} - Using existing GeoPoint from placeholder: $geopoint');
      }
      // Handle new GeoPoint if a new location is provided
      if (phaseControllers[i]['geopoint'] != null &&
          phaseControllers[i]['geopoint'] is GeoPoint) {
        geopoint = phaseControllers[i]['geopoint'];
        print('Phase ${i + 1} - GeoPoint from controller is valid: $geopoint');
      } else if (phaseControllers[i]['geopoint'] != null) {
        geopoint = GeoPoint(phaseControllers[i]['geopoint']['lat'],
            phaseControllers[i]['geopoint']['lng']);
        print('Phase ${i + 1} - Created GeoPoint from lat/lng: $geopoint');
      } else {
        print('Phase ${i + 1} - GeoPoint is null');
      }

      phases.add({
        'PhaseName': phaseControllers[i]['name']!.text,
        'PhaseLocation': locationText,
        'StartTime': startTime != null ? Timestamp.fromDate(startTime) : null,
        'EndTime': endTime != null ? Timestamp.fromDate(endTime) : null,
        'GeoPoint': geopoint,
      });

      // Log the finalized phase data
      print('Phase ${i + 1} - Finalized Phase Data: ${phases.last}');
    }

    // Collect notifications
    List<Map<String, dynamic>> notifications =
        notificationControllers.map((controller) {
      DateTime? notificationTime;
      try {
        notificationTime = parseDateTimeFromController(controller['time']!);
      } catch (e) {
        notificationTime = null;
      }

      return {
        'NotificationTime': notificationTime != null
            ? Timestamp.fromDate(notificationTime)
            : null,
        'NotificationMessage': controller['text']!.text,
      };
    }).toList();

    // Initialize attendees map
    Map<String, String> attendeesMap = {};
    for (String attendee in attendees.keys) {
      attendeesMap[attendee] = originalAttendees[attendee] ?? 'maybe';
    }
    attendeesMap[widget.username] = originalAttendees[widget.username] ?? 'yes';

    // Create event data
    Map<String, dynamic> eventData = {
      'EventName': eventNameController.text,
      'Details': eventDetailsController.text,
      'HostName': widget.username,
      'Attendees': attendeesMap,
      'Timeline': phases,
      'Notifications': notifications,
    };

    try {
      // Update event in Firestore
      DocumentReference eventDocRef =
          firestore.collection('Events').doc(widget.eventID);
      DocumentSnapshot initialEventDoc = await eventDocRef.get();
      Map<String, dynamic> initialEventData =
          initialEventDoc.data() as Map<String, dynamic>;
      List<dynamic> initialTimeline = initialEventData['Timeline'];

      await eventDocRef.update(eventData);

      // Update essential polls based on the new phases
      WriteBatch batch = firestore.batch();
      CollectionReference essentialPollsRef =
          eventDocRef.collection('EssentialPolls');
      QuerySnapshot existingPollsSnapshot = await essentialPollsRef.get();

      // Print the current timeline for debugging
      print('Current Timeline:');
      for (var phase in phases) {
        print('Phase: ${phase['PhaseName']}');
      }

      // Handle essential polls
      List<String> existingPollIDs = [];
      for (var doc in existingPollsSnapshot.docs) {
        existingPollIDs.add(doc.id);
      }

      // Print the existing essential polls for debugging
      print('Existing Essential Polls:');
      for (var doc in existingPollsSnapshot.docs) {
        print('Poll ID: ${doc.id}, Question: ${doc['Question']}');
      }

      List<String> initialPhaseNames =
          initialTimeline.map((p) => p['PhaseName'] as String).toList();
      List<String> finalPhaseNames =
          phases.map((p) => p['PhaseName'] as String).toList();

      // Rename or delete existing polls
      for (var doc in existingPollsSnapshot.docs) {
        String pollID = doc.id;
        String question = doc['Question'];
        String? phaseName;

        try {
          phaseName =
              finalPhaseNames.firstWhere((name) => question.contains(name));
        } catch (e) {
          phaseName = null;
        }

        if (phaseName != null) {
          // Update the question string if needed
          String newQuestion = 'RSVP for $phaseName';
          if (question != newQuestion) {
            batch.update(doc.reference, {'Question': newQuestion});
            print('Updated Poll: $pollID, New Question: $newQuestion');
          }
        } else {
          // Delete the poll if the phase no longer exists
          batch.delete(doc.reference);
          print('Deleted Poll: $pollID');
        }
      }

      // Create new polls for new phases
      for (var phase in phases) {
        if (!initialPhaseNames.contains(phase['PhaseName'])) {
          String pollQuestion = 'RSVP for ${phase['PhaseName']}';
          DateTime now = DateTime.now();
          DateTime tomorrowLateNight =
              DateTime(now.year, now.month, now.day + 1, 23, 59);
          Map<String, dynamic> pollData = {
            'Question': pollQuestion,
            'Yes': [widget.username],
            'No': {},
            'CloseTime': Timestamp.fromDate(tomorrowLateNight),
            'IsClosed': false,
          };
          DocumentReference newPollRef = essentialPollsRef.doc();
          batch.set(newPollRef, pollData);
          print('Created New Poll: ${newPollRef.id}, Question: $pollQuestion');
        }
      }

      // Add the event ID to the 'Events' field for the host and each attendee
      DocumentReference hostDocRef =
          firestore.collection('Users').doc(widget.username);
      batch.update(hostDocRef, {
        'Events': FieldValue.arrayUnion([widget.eventID])
      });

      Timestamp timestamp = Timestamp.now();
      DocumentSnapshot hostDoc =
          await firestore.collection('Users').doc(widget.username).get();
      String hostFirstName = hostDoc['FirstName'] ?? widget.username;
      String hostLastName = hostDoc['LastName'] ?? '';
      List<String> removedAttendees = originalAttendees.keys
          .where((attendee) =>
              !attendees.containsKey(attendee) && attendee != widget.username)
          .toList();

      for (String friend in removedAttendees) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(friend);
        batch.update(userDocRef, {
          'Messages': FieldValue.arrayUnion([
            {
              'text':
                  '$hostFirstName $hostLastName has cancelled ${eventData['EventName']}.',
              'type': 'event cancelled',
              'eventID': widget.eventID,
              'timestamp': timestamp
            }
          ]),
          'NewMessages': true,
          'Events': FieldValue.arrayRemove([widget.eventID])
        });
      }

      for (String attendee in attendees.keys) {
        DocumentReference userDocRef =
            firestore.collection('Users').doc(attendee);
        Map<String, dynamic> updateData = {
          'Events': FieldValue.arrayUnion([widget.eventID]),
        };

        if (!originalAttendees.containsKey(attendee) &&
            attendee != widget.username) {
          updateData['Messages'] = FieldValue.arrayUnion([
            {
              'text':
                  '$hostFirstName $hostLastName has invited you to ${eventNameController.text}. You have 24 hours to RSVP!',
              'type': 'event invitation',
              'eventID': widget.eventID,
              'timestamp': timestamp
            }
          ]);
          updateData['NewMessages'] = true;
        }

        batch.update(userDocRef, updateData);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Event updated successfully', style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update event: $e',
                  style: AppColors.bodyStyle),
              backgroundColor: AppColors.accentLight),
        );
      }
    }
  }

  Future<void> deleteEvent(String eventID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot hostDoc =
        await firestore.collection('Users').doc(widget.username).get();
    String hostFirstName = hostDoc['FirstName'] ?? widget.username;
    String hostLastName = hostDoc['LastName'] ?? '';

    try {
      DocumentSnapshot eventDoc =
          await firestore.collection('Events').doc(eventID).get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        Map<String, String> attendeesMap =
            Map<String, String>.from(eventData['Attendees'] ?? {});

        WriteBatch batch = firestore.batch();

        for (String attendee in attendeesMap.keys) {
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

        DocumentReference eventDocRef =
            firestore.collection('Events').doc(eventID);
        batch.delete(eventDocRef);
        DocumentReference eventChatRef =
            firestore.collection('Chats').doc(eventID);
        batch.delete(eventChatRef);

        await batch.commit();

        Navigator.pop(context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => EventPage(username: widget.username),
        //   ),
        // );

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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Edit Event', style: AppColors.topStyle),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 15))
            : GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      // padding: const EdgeInsets.only(bottom: 120),
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
                                  color: AppColors.light,
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
                                    Text('Event Name',
                                        style: AppColors.titleStyle),
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
                                phaseGeopoints: phaseGeopoints,
                                onAddPhase: addPhase,
                                onRemovePhase: removePhase,
                                eventID: widget.eventID,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: screenSize.width * 0.05),
                                width: screenSize.width * 0.95,
                                decoration: BoxDecoration(
                                  color: AppColors.light,
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
                                    Text('Additional Details',
                                        style: AppColors.titleStyle),
                                    WideTextBox(
                                      hintText: 'Event Details',
                                      controller: eventDetailsController,
                                      canGrow: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              NotificationsSection(
                                rating: widget.rating,
                                notificationControllers:
                                    notificationControllers,
                                onAddNotification: addNotification,
                                onRemoveNotification: removeNotification,
                              ),
                              const SizedBox(height: 10),
                              AttendeeEntrySection(
                                rating: widget.rating,
                                username: widget.username,
                                onAttendeesChanged: (newAttendees) {
                                  attendees = newAttendees;
                                },
                                existingAttendees: attendees,
                              ),
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 170),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
  }
}
