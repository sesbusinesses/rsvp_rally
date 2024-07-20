import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rsvp_rally/models/database_pusher.dart';

Future<void> enableLocationTracking(
    String username, BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Get current position and update the location
  try {
    await updateCurrentLocation(username);
    print('Current Location Updated for $username');
  } catch (e) {
    print('Error enabling location tracking: $e');
  }

  /*
  // Start listening to location updates. not using anymore.
  Geolocator.getPositionStream(
    desiredAccuracy: LocationAccuracy.high,
    distanceFilter: 1000, // 1000 meters or 1 kilometer
  ).listen((Position position) async {
    await FirebaseFirestore.instance.collection('Users').doc(username).set({
      'location': GeoPoint(position.latitude, position.longitude),
    }, SetOptions(merge: true));
  });
  */
}

Future<void> updateCurrentLocation(String username) async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await FirebaseFirestore.instance.collection('Users').doc(username).set({
      'location': GeoPoint(position.latitude, position.longitude),
    }, SetOptions(merge: true));

    print(
        'Current position for $username: ${position.latitude}, ${position.longitude}');

    // Check if there are any events that have started
    try {
      await checkForStartedEvents(username, position);
    } catch (e) {
      print('error check for started events : $e');
    }
  } catch (e) {
    print('Error updating current location for $username: $e');
  }
}

Future<void> checkForStartedEvents(
    String username, Position currentPosition) async {
  //print('checkForStartedEvents called.');
  // Get the user's document
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('Users').doc(username).get();
  var userData = userDoc.data() as Map<String, dynamic>;

  // Get the list of event IDs from the user's document
  List<dynamic> userEvents = userData['Events'] ?? [];
  if (userEvents.isEmpty) return;

  // Check each event ID to see if it has started
  for (String eventId in userEvents) {
    DocumentSnapshot eventStartedDoc = await FirebaseFirestore.instance
        .collection('Triggers')
        .doc('EventStarted')
        .collection('EventInfo')
        .doc(eventId)
        .get();

    if (eventStartedDoc.exists) {
      // Print message indicating a started event
      //print('You have a started event: $eventId');

      var eventStartedData = eventStartedDoc.data() as Map<String, dynamic>;
      // Check if user is in the OMWUsers array
      List<dynamic> OMWUsers = eventStartedData['OMWUsers'] ?? [];
      if (!OMWUsers.contains(username)) {
        //print('$username is already at the event $eventId.');
        return;
      } else {
        print('checking time and distance.');
        // Get event location from the 'Events' collection
        DocumentSnapshot eventDoc = await FirebaseFirestore.instance
            .collection('Events')
            .doc(eventId)
            .get();
        var eventData = eventDoc.data() as Map<String, dynamic>;
        var eventLocation = eventData['Timeline'][0]['GeoPoint'] as GeoPoint;
        var eventName = eventData['EventName'] as String;
        var eventStartTime = eventStartedData['FirstStartTime'] as Timestamp;

        // Calculate the distance between the user's location and the event location
        double distanceInMeters = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          eventLocation.latitude,
          eventLocation.longitude,
        );

        // Calculate how much time has passed since the event started
        Duration timeElapsed =
            Timestamp.now().toDate().difference(eventStartTime.toDate());

        // Check if timeElapsed is longer than 10 minutes
        Duration timeLimit = const Duration(minutes: 10);
        if (timeElapsed <= timeLimit) {
          // Check if the user is within 1600 meters of the event location
          if (distanceInMeters <= 1600) {
            Timestamp timestamp = Timestamp.now();
            //print('with in the distance.');
            // Move the username from OMWUsers to PresentUsers array
            await FirebaseFirestore.instance
                .collection('Triggers')
                .doc('EventStarted')
                .collection('EventInfo')
                .doc(eventId)
                .update({
              'PresentUsers': FieldValue.arrayUnion([username]),
              'OMWUsers': FieldValue.arrayRemove([username]),
            });

            await FirebaseFirestore.instance
                .collection('Users')
                .doc(username)
                .update({
              'Messages': FieldValue.arrayUnion([
                {
                  'text': 'You made it to $eventName on time.',
                  'type': 'Present',
                  'timestamp': timestamp
                }
              ]),
              'NewMessages': true,
            });

            //rating change
            await changeRatingFour(username, eventId);

            //print('You made it to the event on time.');
          } else {
            Duration timeLeft = timeLimit - timeElapsed;
            Timestamp timestamp = Timestamp.now();
            // A new message to let the user know that you are still not at the event location.
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(username)
                .update({
              'Messages': FieldValue.arrayUnion([
                {
                  'text':
                      'You are still not close enough to $eventName location. You have ${timeLeft.inMinutes} minutes to keep your rating!',
                  'type': 'Not there yet',
                  'timestamp': timestamp
                }
              ]),
              'NewMessages': true,
            });
          }
        } else {
          //print('You are late to the event.');
          Timestamp timestamp = Timestamp.now();

          try {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(username)
                .update({
              'Messages': FieldValue.arrayUnion([
                {
                  'text':
                      'OH NO! You were late to $eventName. Get ready early next time.',
                  'type': 'Late',
                  'timestamp': timestamp
                }
              ]),
              'NewMessages': true,
            });
          } catch (e) {
            print('Error updating message: $e');
          }

          await FirebaseFirestore.instance
              .collection('Triggers')
              .doc('EventStarted')
              .collection('EventInfo')
              .doc(eventId)
              .update({
            'LateUsers': FieldValue.arrayUnion([username]),
            'OMWUsers': FieldValue.arrayRemove([username]),
          });

          //minus rating by 0.20
          await changeRatingFive(username, eventId);
        }
      }
    }
  }
}

Future<void> requestPermission(BuildContext context) async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    if (kDebugMode) {
      print('Location permission granted');
    }
  } else if (status.isDenied) {
    try {
      requestPermission(context);
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
    }
  }
}

Future<bool> checkLocationPermissionStatus() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  return permission != LocationPermission.denied &&
      permission != LocationPermission.deniedForever;
}
