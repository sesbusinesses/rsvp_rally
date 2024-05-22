import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

void fetchDataFromFirestore() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Assuming you have a collection named 'users'. Change this to your specific collection name.
  CollectionReference users = firestore.collection('Users');

  try {
    // Fetch all documents in the collection
    QuerySnapshot querySnapshot = await users.get();

    // Iterate through all the documents and print their data
    for (var doc in querySnapshot.docs) {
      log(doc.data().toString()); // This prints each document's data
    }
  } catch (e) {
    print("Error fetching data: $e");
  }

  // Assuming you have a collection named 'users'. Change this to your specific collection name.
  CollectionReference events = firestore.collection('Events');

  try {
    // Fetch all documents in the collection
    QuerySnapshot querySnapshot = await events.get();

    // Iterate through all the documents and print their data
    for (var doc in querySnapshot.docs) {
      log(doc.data().toString()); // This prints each document's data
    }
  } catch (e) {
    print("Error fetching data: $e");
  }
}

Future<List<String>> getUserEvents(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> eventIds = [];

  try {
    // Directly access the user's document using the username as the document ID
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (!userDoc.exists) {
      print("No user found with username $username");
      return eventIds; // Return an empty list if the user doesn't exist
    }

    // Get the list of event IDs the user is associated with
    eventIds = List.from(userDoc.get('Events'));

    return eventIds;
  } catch (e) {
    print("Error fetching user events: $e");
    return eventIds; // Return the potentially empty list in case of error
  }
}

Future<List<Map<String, dynamic>>> getEventDetails(
    List<String> eventIds) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to the 'Events' collection
  CollectionReference events = firestore.collection('Events');
  List<Map<String, dynamic>> eventDetails = [];

  try {
    for (String eventId in eventIds) {
      DocumentSnapshot eventDoc = await events.doc(eventId).get();
      if (eventDoc.exists) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        // Assuming the 'EventName' and 'Timeline' fields exist and 'StartTime' is in the first timeline phase
        String eventName = data['EventName'];
        Timestamp startTimeStamp = data['Timeline'][0]
            ['StartTime']; // Assuming there is at least one timeline phase
        DateTime startTime = startTimeStamp.toDate();

        eventDetails.add({
          'EventName': eventName,
          'StartTime': startTime,
        });

        print("Event: $eventName, Start Time: $startTime");
      } else {
        print("No event found with ID $eventId");
      }
    }
  } catch (e) {
    print("Error fetching event details: $e");
  }

  return eventDetails;
}

Future<double?> getUserRating(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Access the user's document by the username
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (!userDoc.exists) {
      print("No user found with username $username");
      return null; // Return null if the user doesn't exist
    }

    // Extract the rating from the document; assuming 'Rating' is the field name
    double? rating = userDoc.get('Rating');

    return rating;
  } catch (e) {
    print("Error fetching user rating: $e");
    return null; // Return null in case of any errors
  }
}

Future<List<Map<String, dynamic>>> fetchTimeline(String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> timelineData = [];

  try {
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(eventID).get();

    if (eventDoc.exists) {
      var eventData = eventDoc.data() as Map<String, dynamic>;
      var timeline = eventData['Timeline'] as List<dynamic>;

      for (var phase in timeline) {
        Map<String, dynamic> phaseData = {
          'startTime': phase['StartTime'].toDate().toString(),
          'phaseName': phase['PhaseName'],
          'phaseLocation': phase['PhaseLocation'],
          'endTime': phase.containsKey('EndTime')
              ? phase['EndTime'].toDate().toString()
              : null
        };
        timelineData.add(phaseData);
      }
    }
  } catch (e) {
    print("Error fetching timeline: $e");
  }
  print("Fetched timeline data: $timelineData");

  return timelineData;
}

Future<Map<String, dynamic>> fetchEventDetails(String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentSnapshot eventDoc =
      await firestore.collection('Events').doc(eventID).get();

  if (eventDoc.exists) {
    var eventData = eventDoc.data() as Map<String, dynamic>;
    return {
      'eventName': eventData['EventName'],
      'details': eventData['Details'],
      'hostName': eventData['HostName']
    };
  } else {
    throw Exception('Event not found');
  }
}

Future<List<Map<String, dynamic>>> fetchEventAttendees(String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentSnapshot eventDoc =
      await firestore.collection('Events').doc(eventID).get();
  List<Map<String, dynamic>> attendeesDetails = [];

  if (eventDoc.exists) {
    var eventData = eventDoc.data() as Map<String, dynamic>;
    List<dynamic> attendeesUsernames = eventData['Attendees'] ?? [];

    for (String username in attendeesUsernames) {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String comingStatus = await isComing(
            eventID, username); // Fetch and include coming status
        attendeesDetails.add({
          'username': username,
          'firstName': userData['FirstName'],
          'lastName': userData['LastName'],
          'rating': userData['Rating'],
          'isComing': comingStatus // Include coming status
        });
      }
    }
  }
  return attendeesDetails;
}

Future<String> isComing(String eventID, String userID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  try {
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(eventID).get();
    if (eventDoc.exists) {
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> polls = eventData['Polls'] ?? {};

      bool hasRespondedYes = false;
      bool hasRespondedNo = true; // Assume 'no' until a 'yes' is found

      for (var pollName in polls.keys) {
        if (pollName.startsWith('RSVP for')) {
          var responses = polls[pollName];
          if (responses['Yes'] != null && responses['Yes'].contains(userID)) {
            hasRespondedYes = true;
          }
          if (responses['No'] != null && responses['No'].contains(userID)) {
            hasRespondedNo = hasRespondedNo && true;
          } else {
            hasRespondedNo = false;
          }
        }
      }

      if (hasRespondedYes) return 'yes';
      if (hasRespondedNo) return 'no';
      return 'maybe';
    } else {
      return 'maybe'; // Default response if the event does not exist
    }
  } catch (e) {
    print("Error fetching event or processing data: $e");
    return 'maybe'; // Default response in case of error
  }
}
