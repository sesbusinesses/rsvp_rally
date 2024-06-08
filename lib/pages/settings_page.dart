import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final String username;
  final double userRating;

  const SettingsPage(
      {required this.username, required this.userRating, super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://sesbusinesses.me');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
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
                    onTap: () {
                      _launchURL();
                    },
                    child: Text("Visit our website",
                        style: TextStyle(
                          color: getInterpolatedColor(userRating),
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        )),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
