import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/pages/chat_page.dart';
import 'package:rsvp_rally/pages/edit_event_page.dart';
import 'package:rsvp_rally/models/colors.dart'; // Ensure this import exists

class BottomNav extends StatefulWidget {
  final String eventID;
  final String username;
  final int selectedIndex;
  final double rating;

  const BottomNav({
    Key? key,
    required this.eventID,
    required this.username,
    required this.selectedIndex,
    required this.rating,
  }) : super(key: key);

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  void _onItemTapped(int index) {
    if (index != widget.selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsPage(
                username: widget.username,
                eventID: widget.eventID,
                userRating: widget.rating,
              ),

            ),
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PollPage(
                rating: widget.rating,
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
              builder: (context) => ChatPage(
                rating: widget.rating,
                eventID: widget.eventID,
                username: widget.username,
              ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          height: 50, // Increased height to fit icons and dot
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: getInterpolatedColor(widget.rating),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.document_scanner,
                index: 0,
                selected: widget.selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.bar_chart,
                index: 1,
                selected: widget.selectedIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.chat,
                index: 2,
                selected: widget.selectedIndex == 2,
              ),
              _buildNavItem(
                icon: Icons.edit,
                index: 3,
                selected: widget.selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required bool selected}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (selected)
            Positioned(
              top: -10, // Positioned above the icon
              child: Container(
                width: 8,
                height: 10,
                decoration: BoxDecoration(
                  color: getInterpolatedColor(widget.rating),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Icon(
            icon,
            size: 24,
            color: selected ? Colors.grey[900] : Colors.grey[500],
          ),
        ],

      ),
    );
  }
}
