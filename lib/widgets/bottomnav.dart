import 'dart:math';

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

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isDragging = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset _touchPosition = Offset.zero;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _onItemTapped(int index) {
    if (index != widget.selectedIndex) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
        _highlightedIndex = -1;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
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
                  eventID: widget.eventID,
                  username: widget.username,
                  rating: widget.rating,
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
      });
    } else {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
        _highlightedIndex = -1;
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isDragging = false;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _startDrag() {
    setState(() {
      _isDragging = true;
      _isExpanded = true;
      _controller.forward();
    });
  }

  // Update this method to accept LongPressMoveUpdateDetails
  void _updateDrag(LongPressMoveUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _touchPosition = details.localPosition;
        _highlightedIndex = _calculateClosestIcon();
      });
    }
  }

  void _endDrag() {
    if (_isDragging && _highlightedIndex != -1) {
      _onItemTapped(_highlightedIndex);
    } else {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
        _highlightedIndex = -1;
      });
    }
  }

  int _calculateClosestIcon() {
    double radius = 40;
    List<Offset> iconPositions = [
      Offset(radius + radius * cos(144 * pi / 180.0),
          radius + radius * sin(144 * pi / 180.0) - 220),
      Offset(radius + radius * cos(36 * pi / 180.0),
          radius + radius * sin(36 * pi / 180.0) - 220),
      Offset(radius + radius * cos(72 * pi / 180.0),
          radius + radius * sin(72 * pi / 180.0) - 220),
      Offset(radius + radius * cos(108 * pi / 180.0),
          radius + radius * sin(108 * pi / 180.0) - 220),
    ];

    double minDistance = double.infinity;
    int closestIndex = -1;
    for (int i = 0; i < iconPositions.length; i++) {
      double distance = (_touchPosition - iconPositions[i]).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onLongPressStart: (_) => _startDrag(),
        // Update to use the correct type of details
        onLongPressMoveUpdate: _updateDrag,
        onLongPressEnd: (_) => _endDrag(),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_isExpanded)
              Positioned(
                bottom: 70, // Adjust to position arc above the button
                child: ArcNav(
                  animation: _animation,
                  onItemTapped: _onItemTapped,
                  highlightedIndex: _highlightedIndex,
                ),
              ),
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                _isExpanded ? Icons.close : Icons.more_horiz,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArcNav extends StatelessWidget {
  final Animation<double> animation;
  final Function(int) onItemTapped;
  final int highlightedIndex;

  const ArcNav({
    super.key,
    required this.animation,
    required this.onItemTapped,
    required this.highlightedIndex,
  });

  @override
  Widget build(BuildContext context) {
    double radius = 120; // Radius for the arc

    return FadeTransition(
      opacity: animation,
      child: SizedBox(
        width: 2 * radius,
        height: radius + 60, // Extra space for positioning
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            _buildIcon(context, Icons.document_scanner, 0, 144, radius),
            _buildIcon(context, Icons.bar_chart, 1, 36, radius),
            _buildIcon(context, Icons.chat, 2, 72, radius),
            _buildIcon(context, Icons.edit, 3, 108, radius),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, int index,
      double angle, double radius) {
    double rad = angle * (pi / 180.0);
    return Positioned(
      left: radius + radius * cos(rad) - 25, // Center horizontally
      bottom: radius + radius * sin(rad) - 230, // Align to arc path
      child: CircleAvatar(
        radius: highlightedIndex == index ? 28 : 25,
        backgroundColor: highlightedIndex == index ? Colors.blue : Colors.white,
        child: Icon(
          icon,
          color: highlightedIndex == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
