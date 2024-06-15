import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        {
          'text':
              'Account created at ${DateTime.now()}! Welcome to RSVP Rally!',
          'type': 'account creation',
        }
      ],
      'NewMessages': true,
      'Requests': [],
    };
    await _firestore.collection('Users').doc(username).set(newUser);
  }
}

Future<String?> uploadChatPhotoBase64(XFile image) async {
  try {
    final file = File(image.path);
    if (!file.existsSync()) {
      developer.log("File does not exist at the provided path");
      return null;
    }

    // Read the file as bytes
    List<int> imageBytes = await file.readAsBytes();
    // Convert bytes to Base64
    String base64String = base64Encode(imageBytes);
    String base64Image = 'data:image/jpeg;base64,$base64String';

    developer.log("Base64 Image: $base64Image");
    return base64Image; // Return the Base64 encoded image string
  } catch (e) {
    developer.log('Error encoding photo: $e');
    return null;
  }
}

Future<void> sendMessageWithPhotoBase64(String eventID, String username, XFile image) async {
  String? base64Image = await uploadChatPhotoBase64(image);
  if (base64Image != null) {
    await FirebaseFirestore.instance.collection('Chats').doc(eventID).update({
      'Messages': FieldValue.arrayUnion([
        {'username': username, 'photoURL': base64Image, 'type': 'photo'}
      ])
    });
  } else {
    developer.log('Base64 Image is null. Failed to encode photo.');
  }
}

Future<String?> uploadChatPhoto(String eventID, XFile image) async {
  try {
    // Verify if the file exists
    File file = File(image.path);
    if (!file.existsSync()) {
      print("File does not exist at path: ${image.path}");
      throw Exception("File does not exist");
    }

    // Create a unique reference in Firebase Storage
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_photos/$eventID/$fileName');
    
    // Upload the file to Firebase Storage
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

    // Ensure upload was successful
    if (snapshot.state == TaskState.success) {
      String downloadURL = await snapshot.ref.getDownloadURL();
      print('Upload successful, download URL: $downloadURL');
      return downloadURL;
    } else {
      throw Exception('Upload failed');
    }
  } catch (e) {
    print('Error uploading photo: $e');
    return null;
  }
}

Future<void> sendMessageWithPhoto(String eventID, String username, XFile image) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference chatRef = firestore.collection('Chats').doc(eventID);

  try {
    // Verify if the file exists
    File file = File(image.path);
    if (!file.existsSync()) {
      throw Exception("File does not exist at path: ${image.path}");
    }

    // Read the image file as a base64-encoded string
    String base64Image = base64Encode(await file.readAsBytes());
    String photoDataUrl = 'data:image/${image.mimeType?.split('/')[1] ?? 'jpeg'};base64,$base64Image';

    // Check if the chat document exists, if not create it
    DocumentSnapshot chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) {
      await chatRef.set({
        'EventID': eventID,
        'Messages': []
      });
    }

    // Add the photo data URL to the Messages array
    await chatRef.update({
      'Messages': FieldValue.arrayUnion([
        {
          'username': username,
          'photoDataUrl': photoDataUrl,
          'type': 'photo'
        }
      ])
    });

    print('Photo message sent successfully');
  } catch (e) {
    print('Error sending photo message: $e');
  }
}


Future<void> sendMessage(String eventID, String username, String message) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference chatRef = firestore.collection('Chats').doc(eventID);

  try {
    DocumentSnapshot chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      // Create a new document if it doesn't exist
      await chatRef.set({'EventID': eventID, 'Messages': []});
    }

    // Update the Messages array
    await chatRef.update({
      'Messages': FieldValue.arrayUnion([
        {username: message}
      ])
    });
  } catch (e) {
    print('Error sending message: $e');
  }
}
