// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rsvp_rally/pages/login_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://sesbusinesses.me/rsvp_rally');
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

    if (mounted) {
      _showSnackBar('Location tracking enabled.');
    }
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (mounted) {
      _showSnackBar('Location tracking stopped.');
    }
  }

  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<void> _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      if (kDebugMode) {
        print('Location permission granted');
      }
    } else if (status.isDenied) {
      try {
        _requestPermission();
      } catch (e) {
        if (kDebugMode) {
          print('Error requesting location permission: $e');
        }
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LogInPage()),
        (Route<dynamic> route) => false,
      );
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
              Center(
                child: Column(
                  children: [
                    WideButton(
                      buttonText: 'Enable location tracking',
                      onPressed: _enableLocationTracking,
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    WideButton(
                      buttonText: 'Sign Out',
                      onPressed: _signOut,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Have any questions? ",
                          style:
                              TextStyle(fontSize: 16.0, color: AppColors.dark),
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
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
