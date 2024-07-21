import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart'; // Ensure this import exists

class CustomTabSwitcher extends StatelessWidget {
  final List<IconData> tabs;
  final List<String> subtitles;
  final int selectedIndex;
  final Function(int) onTabChanged;
  final double userRating;
  final EdgeInsets padding;
  final double iconSize;

  const CustomTabSwitcher({
    super.key,
    required this.tabs,
    required this.subtitles,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.userRating,
    this.padding = const EdgeInsets.all(0),
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    Color selectedColor = getInterpolatedColor(userRating);
    Color unselectedColor = Colors.grey;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.asMap().entries.map((entry) {
          int index = entry.key;
          IconData icon = entry.value;
          bool isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: isSelected ? null : () => onTabChanged(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0), // Increase the clickable area
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitles[index],
                    style: AppColors.subtitleStyle.copyWith(
                        fontSize: 12,
                        color: isSelected ? selectedColor : unselectedColor),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 2,
                    width: isSelected ? 60 : 0,
                    color: isSelected ? selectedColor : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
