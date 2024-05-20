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
      print(doc.data()); // This prints each document's data
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
      print(doc.data()); // This prints each document's data
    }
  } catch (e) {
    print("Error fetching data: $e");
  }
}

void getUserEvents(String username) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to the 'Users' collection
  CollectionReference users = firestore.collection('Users');

  try {
    // Query the 'Users' collection to find the user by their username
    QuerySnapshot userQuery =
        await users.where('Username', isEqualTo: username).get();

    if (userQuery.docs.isEmpty) {
      print("No user found with username $username");
      return;
    }

    // Assuming there's only one matching document for a username
    var userDoc = userQuery.docs.first;

    // Get the list of event IDs the user is associated with
    List<dynamic> eventIds = userDoc.get('Events');

    if (eventIds.isEmpty) {
      print("User $username has no events.");
      return;
    }

    // Reference to the 'Events' collection
    CollectionReference events = firestore.collection('Events');

    // Fetch each event by its ID
    for (String eventId in eventIds) {
      DocumentSnapshot eventDoc = await events.doc(eventId).get();
      if (eventDoc.exists) {
        print("Event found: ${eventDoc.data()}");
      } else {
        print("No event found with ID $eventId");
      }
    }
  } catch (e) {
    print("Error fetching user events: $e");
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
