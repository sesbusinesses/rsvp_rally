import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';

class BottomNav extends StatefulWidget {
  final String eventID;
  final String username;
  final int selectedIndex;
  final double rating;
  final PageController pageController;
  final Function(int) onPageChanged;

  const BottomNav({
    super.key,
    required this.eventID,
    required this.username,
    required this.selectedIndex,
    required this.rating,
    required this.pageController,
    required this.onPageChanged,
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
      widget.pageController.jumpToPage(index);
      widget.onPageChanged(index);
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
            label: "Details",
            index: 0,
            selected: widget.selectedIndex == 0,
            spacing: 8.0, // Adjust this value as needed
          ),
          _buildNavItem(
            icon: Icons.bar_chart,
            label: "Polls",
            index: 1,
            selected: widget.selectedIndex == 1,
            spacing: 8.0, // Adjust this value as needed
          ),
          _buildNavItem(
            icon: Icons.chat,
            label: "Chat",
            index: 2,
            selected: widget.selectedIndex == 2,
            spacing: 8.0, // Adjust this value as needed
          ),
          if (isHost)
            _buildNavItem(
              icon: Icons.edit,
              label: "Edit",
              index: 3,
              selected: widget.selectedIndex == 3,
              spacing: 8.0, // Adjust this value as needed
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool selected,
    double spacing = 100.0, // Default spacing value
  }) {
    Color selectedColor = getInterpolatedColor(widget.rating);
    Color unselectedColor = Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 20.0), // Increase the clickable area
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Adjustable spacing
            Icon(
              icon,
              size: 24,
              color: selected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4), // Space between icon and text
            Text(
              label,
              style: AppColors.subtitleStyle.copyWith(
                fontSize: 12,
                color: selected ? selectedColor : unselectedColor,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
