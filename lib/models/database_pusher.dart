import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class DataPusher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNewUser(
      String username, String firstName, String lastName) async {
    final newUser = {
      'FirstName': firstName,
      'LastName': lastName,
      'Rating': 0.99,
      'Events': ['EAO5TLf41xsNEoL7FOVm'],
      'Friends': ['spark259', 'sherwinnw22']
    };
    await _firestore.collection('Users').doc(username).set(newUser);
  }
}
