import 'package:cloud_firestore/cloud_firestore.dart';

class DataPusher {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNewUser(String uid, String name, String email) async {
    final newUser = {
      'uid': uid,
      'UserEmail': email,
      'Rating': 0.99,
      'Events': [],
      'Friends': []
    };
    await _firestore.collection('Users').doc(name).set(newUser);
  }
}
