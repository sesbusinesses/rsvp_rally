import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> enableLocationTracking(
    String username, BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  StreamSubscription<Position>? _positionStreamSubscription;

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

  // Get current position
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  await FirebaseFirestore.instance.collection('Users').doc(username).set({
    'location': GeoPoint(position.latitude, position.longitude),
  }, SetOptions(merge: true));

  // Start listening to location updates
  _positionStreamSubscription = Geolocator.getPositionStream(
    desiredAccuracy: LocationAccuracy.high,
    distanceFilter: 10,
  ).listen((Position position) async {
    await FirebaseFirestore.instance.collection('Users').doc(username).set({
      'location': GeoPoint(position.latitude, position.longitude),
    }, SetOptions(merge: true));
  });
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
