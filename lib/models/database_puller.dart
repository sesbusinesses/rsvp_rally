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
