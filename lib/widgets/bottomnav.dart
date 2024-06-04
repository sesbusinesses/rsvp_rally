import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/pages/chat_page.dart';
import 'package:rsvp_rally/pages/edit_event_page.dart';

class BottomNav extends StatefulWidget {
  final String eventID;
  final String username;
  final int selectedIndex;
  final double rating;

  const BottomNav({
    super.key,
    required this.eventID,
    required this.username,
    required this.selectedIndex,
    required this.rating,
  });

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(
                username: widget.username,
                eventID: widget.eventID,
                userRating: widget.rating),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PollPage(
              eventID: widget.eventID,
              username: widget.username,
            ),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(eventID: widget.eventID),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditEventPage(
              rating: widget.rating,
              eventID: widget.eventID,
              username: widget.username,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          iconButton(Icons.document_scanner, 0),
          iconButton(Icons.bar_chart, 1),
          iconButton(Icons.chat, 2),
          iconButton(Icons.edit, 3),
        ],
      ),
    );
  }

  Widget iconButton(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        icon,
        color: widget.selectedIndex == index ? Colors.black : Colors.grey,
        size: 30,
      ),
    );
  }
}
