import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/pages/chat_page.dart';
import 'package:rsvp_rally/pages/edit_event_page.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';

class EventPageView extends StatefulWidget {
  final String eventID;
  final String username;
  final double rating;

  const EventPageView({
    super.key,
    required this.eventID,
    required this.username,
    required this.rating,
  });

  @override
  _EventPageViewState createState() => _EventPageViewState();
}

class _EventPageViewState extends State<EventPageView> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    checkIfHost();
  }

  Future<void> checkIfHost() async {
    DocumentSnapshot eventDoc = await FirebaseFirestore.instance
        .collection('Events')
        .doc(widget.eventID)
        .get();

    if (eventDoc.exists) {
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        isHost = eventData['HostName'] == widget.username;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      DetailsPage(
        username: widget.username,
        eventID: widget.eventID,
        userRating: widget.rating,
      ),
      PollPage(
        rating: widget.rating,
        eventID: widget.eventID,
        username: widget.username,
      ),
      ChatPage(
        rating: widget.rating,
        eventID: widget.eventID,
        username: widget.username,
      ),
    ];

    if (isHost) {
      pages.add(EditEventPage(
        rating: widget.rating,
        eventID: widget.eventID,
        username: widget.username,
      ));
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: BottomNav(
        eventID: widget.eventID,
        username: widget.username,
        selectedIndex: _selectedIndex,
        rating: widget.rating,
        pageController: _pageController,
        onPageChanged: _onPageChanged,
      ),
    );
  }
}
