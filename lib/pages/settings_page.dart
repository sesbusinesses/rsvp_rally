import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class SettingsPage extends StatefulWidget {
  final String username;
  final double userRating;

  const SettingsPage({
    required this.username,
    required this.userRating,
    super.key,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://sesbusinesses.me');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _enableLocationTracking() async {
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

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.username)
        .set({
      'location': GeoPoint(position.latitude, position.longitude),
    }, SetOptions(merge: true));

    // Start listening to location updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ).listen((Position position) async {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.username)
          .set({
        'location': GeoPoint(position.latitude, position.longitude),
      }, SetOptions(merge: true));
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('Location permission granted');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Have any questions? ",
                    style: TextStyle(fontSize: 16.0, color: AppColors.dark),
                  ),
                  GestureDetector(
                    onTap: _launchURL,
                    child: Text(
                      "Visit our website",
                      style: TextStyle(
                        color: getInterpolatedColor(widget.userRating),
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _enableLocationTracking,
                      child: const Text('Enable location tracking'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _stopLocationTracking,
                      child: const Text('Stop location tracking'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }
}