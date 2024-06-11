import 'package:cloud_firestore/cloud_firestore.dart';

class DataPusher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNewUser(
      String username, String firstName, String lastName) async {
    final newUser = {
      'FirstName': firstName,
      'LastName': lastName,
      'Rating': 0.99,
      'Events': [],
      'Friends': [],
      'Messages': [
        'Account created at ${DateTime.now()}! Welcome to RSVP Rally!'
      ],
      'NewMessages': true,
    };
    await _firestore.collection('Users').doc(username).set(newUser);
  }
}

Future<void> sendMessage(String eventID, String username, String message) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference chatRef = firestore.collection('Chats').doc(eventID);

  try {
    DocumentSnapshot chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      // Create a new document if it doesn't exist
      await chatRef.set({
        'EventID': eventID,
        'Messages': []
      });
    }

    // Update the Messages array
    await chatRef.update({
      'Messages': FieldValue.arrayUnion([{'$username': message}])
    });
  } catch (e) {
    print('Error sending message: $e');
  }
}

