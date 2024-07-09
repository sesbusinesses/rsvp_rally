// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rsvp_rally/pages/login_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'package:rsvp_rally/models/location_service.dart';

class SettingsPage extends StatefulWidget {
  final String username;
  final double userRating;

  const SettingsPage({
    required this.username,
    required this.userRating,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // requestPermission(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://sesbusinesses.me/rsvp_support.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
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

  Future<void> _checkLocationTrackingStatus() async {
    bool isTrackingEnabled = await checkLocationPermissionStatus();
    _showSnackBar(isTrackingEnabled
        ? 'Location tracking is enabled.'
        : 'Location tracking is disabled.');
  }

  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message, style: AppColors.bodyStyle),
              backgroundColor: AppColors.accentLight),
        );
      }
    });
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
                      buttonText: 'Check location tracking status',
                      onPressed: _checkLocationTrackingStatus,
                    ),
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
}
