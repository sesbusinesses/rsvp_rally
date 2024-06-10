import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/widgets/message_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class InboxPage extends StatefulWidget {
  final String username;
  final double userRating;

  const InboxPage({
    required this.username,
    required this.userRating,
    super.key,
  });

  @override
  InboxPageState createState() => InboxPageState();
}

class InboxPageState extends State<InboxPage> {
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(widget.username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> userMessages = userData['Messages'] ?? [];
      setState(() {
        messages = List<String>.from(userMessages);
      });
    }

    messages = messages.reversed.toList();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://sesbusinesses.me');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return PopScope(
        onPopInvoked: (bool didPop) {
          Future.delayed(Duration.zero, () {
            Navigator.pop(context, true);
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return EventPage(username: widget.username);
            }));
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Inbox'),
            surfaceTintColor: Colors.transparent,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 70), // Add bottom padding to avoid overlap
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return MessageCard(
                      username: widget.username,
                      rating: widget.userRating,
                      message: messages[index],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: AppColors
                      .light, // Light background color for the bottom section
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
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
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
