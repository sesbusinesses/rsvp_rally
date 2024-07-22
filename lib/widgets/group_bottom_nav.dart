import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';

class GroupBottomNav extends StatefulWidget {
  final String groupID;
  final String username;
  final int selectedIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final double userRating;

  const GroupBottomNav({
    super.key,
    required this.groupID,
    required this.username,
    required this.selectedIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.userRating,
  });

  @override
  _GroupBottomNavState createState() => _GroupBottomNavState();
}

class _GroupBottomNavState extends State<GroupBottomNav> {
  bool isHost = false;

  @override
  void initState() {
    super.initState();
    checkIfHost();
  }

  Future<void> checkIfHost() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupID)
        .get();

    if (groupDoc.exists) {
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      setState(() {
        isHost = groupData['Host'] == widget.username;
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
            color: getInterpolatedColor(
                widget.userRating), // You can adjust this color as needed
            width: AppColors.borderWidth,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.calendar_today,
            label: "Upload Availability",
            index: 0,
            selected: widget.selectedIndex == 0,
            spacing: 8.0, // Adjust this value as needed
          ),
          _buildNavItem(
            icon: Icons.calendar_view_week,
            label: "Current Availability",
            index: 1,
            selected: widget.selectedIndex == 1,
            spacing: 8.0, // Adjust this value as needed
          ),
          _buildNavItem(
            icon: Icons.poll,
            label: "Polls",
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
    Color selectedColor = getInterpolatedColor(
        widget.userRating); // You can adjust this color as needed
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
