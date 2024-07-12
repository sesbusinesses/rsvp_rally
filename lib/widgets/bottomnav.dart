import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/details_page.dart';
import 'package:rsvp_rally/pages/poll_page.dart';
import 'package:rsvp_rally/pages/chat_page.dart';
import 'package:rsvp_rally/pages/edit_event_page.dart';
import 'package:rsvp_rally/models/colors.dart'; // Ensure this import exists
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _onItemTapped(int index) {
    if (index != widget.selectedIndex) {
      final direction = index > widget.selectedIndex ? AxisDirection.right : AxisDirection.left;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            switch (index) {
              case 0:
                return DetailsPage(
                  username: widget.username,
                  eventID: widget.eventID,
                  userRating: widget.rating,
                );
              case 1:
                return PollPage(
                  rating: widget.rating,
                  eventID: widget.eventID,
                  username: widget.username,
                );
              case 2:
                return ChatPage(
                  rating: widget.rating,
                  eventID: widget.eventID,
                  username: widget.username,
                );
              case 3:
                if (isHost) {
                  return EditEventPage(
                    rating: widget.rating,
                    eventID: widget.eventID,
                    username: widget.username,
                  );
                }
                break;
            }
            return Container(); // Fallback in case of incorrect index
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: direction == AxisDirection.right ? begin : Offset(-1.0, 0.0), end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Adjust height if needed
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: getInterpolatedColor(widget.rating),
            width: AppColors.borderWidth,
          ),
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
          if (isHost)
            _buildNavItem(
              icon: Icons.edit,
              index: 3,
              selected: widget.selectedIndex == 3,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required int index, required bool selected}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (selected)
            Positioned(
              top: -12, // Adjust as necessary
              child: Container(
                width: 8,
                height: 8,
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
