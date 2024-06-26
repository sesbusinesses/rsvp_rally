import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchChatMessagesWithPhotos(
    String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  try {
    DocumentSnapshot chatDoc =
        await firestore.collection('Chats').doc(eventID).get();
    if (chatDoc.exists) {
      List<dynamic> messages = chatDoc.get('Messages');
      return messages.map((msg) => Map<String, dynamic>.from(msg)).toList();
    }
  } catch (e) {
    print('Error fetching chat messages: $e');
  }
  return [];
}

Future<List<Map<String, String>>> fetchChatMessages(String eventID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  try {
    DocumentSnapshot chatDoc =
        await firestore.collection('Chats').doc(eventID).get();
    if (chatDoc.exists) {
      List<dynamic> messages = chatDoc.get('Messages');
      return messages.map((msg) => Map<String, String>.from(msg)).toList();
    }
  } catch (e) {
    print('Error fetching chat messages: $e');
  }
  return [];
}

void fetchDataFromFirestore() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Assuming you have a collection named 'users'. Change this to your specific collection name.
  CollectionReference users = firestore.collection('Users');

  try {
    // Fetch all documents in the collection
    QuerySnapshot querySnapshot = await users.get();

    // Iterate through all the documents and log their data
    for (var doc in querySnapshot.docs) {
      log(doc.data().toString()); // This logs each document's data
    }
  } catch (e) {
    log("Error fetching data: $e");
  }

  // Assuming you have a collection named 'users'. Change this to your specific collection name.
  CollectionReference events = firestore.collection('Events');

  try {
    // Fetch all documents in the collection
    QuerySnapshot querySnapshot = await events.get();

    // Iterate through all the documents and log their data
    for (var doc in querySnapshot.docs) {
      log(doc.data().toString()); // This logs each document's data
    }
  } catch (e) {
    log("Error fetching data: $e");
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
      log("No user found with username $username");
      return eventIds; // Return an empty list if the user doesn't exist
    }

    // Get the list of event IDs the user is associated with
    eventIds = List.from(userDoc.get('Events'));

    return eventIds;
  } catch (e) {
    log("Error fetching user events: $e");
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

        log("Event: $eventName, Start Time: $startTime");
      } else {
        log("No event found with ID $eventId");
      }
    }
  } catch (e) {
    log("Error fetching event details: $e");
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
      log("No user found with username $username");
      return null; // Return null if the user doesn't exist
    }

    // Extract the rating from the document; assuming 'Rating' is the field name
    double? rating = userDoc.get('Rating');

    return rating;
  } catch (e) {
    log("Error fetching user rating: $e");
    return null; // Return null in case of any errors
  }
}

Future<String?> getFullName(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Access the user's document by the username
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (!userDoc.exists) {
      log("No user found with username $username");
      return null; // Return null if the user doesn't exist
    }

    // Extract the first name and last name from the document
    String firstName = userDoc.get('FirstName') ?? '';
    String lastName = userDoc.get('LastName') ?? '';

    // Combine to form the full name
    String fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : null;
  } catch (e) {
    log("Error fetching full name: $e");
    return null; // Return null in case of any errors
  }
}

Future<String?> getUsername(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Check if the user's document exists by the username
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (!userDoc.exists) {
      log("No user found with username $username");
      return null; // Return null if the user doesn't exist
    }

    return username; // The document ID is the username
  } catch (e) {
    log("Error fetching username: $e");
    return null; // Return null in case of any errors
  }
}

Future<String?> pullProfilePicture(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    DocumentSnapshot userDoc = await firestore.collection('Users').doc(username).get();

    if (!userDoc.exists) {
      print("No user found with username $username");
      return null;
    }

    final data = userDoc.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('ProfilePic')) {
      print("Field 'ProfilePic' does not exist for user $username");
      return null;
    }

    return data['ProfilePic'] as String?;
  } catch (e) {
    print('Error fetching profile picture: $e');
    return null;
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
          'startTime': phase['StartTime'],
          'phaseName': phase['PhaseName'],
          'phaseLocation': phase['PhaseLocation'],
          'endTime': phase.containsKey('EndTime') ? phase['EndTime'] : null
        };
        timelineData.add(phaseData);
      }
    }
  } catch (e) {
    log("Error fetching timeline: $e");
  }
  log("Fetched timeline data: $timelineData");

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
    String hostUsername = eventData['HostName'];

    // Add host to the attendees list if not already present
    if (!attendeesUsernames.contains(hostUsername)) {
      attendeesUsernames.add(hostUsername);
    }

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

Future<String> isComing(String eventID, String username) async {
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
          if (responses['Yes'] != null && responses['Yes'].contains(username)) {
            hasRespondedYes = true;
          }
          if (responses['No'] != null && responses['No'].contains(username)) {
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
    log("Error fetching event or processing data: $e");
    return 'maybe'; // Default response in case of error
  }
}
