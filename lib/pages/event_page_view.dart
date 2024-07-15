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

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
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
          EditEventPage(
            rating: widget.rating,
            eventID: widget.eventID,
            username: widget.username,
          ),
        ],
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
