import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart'; // Ensure this import exists

class CustomTabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabChanged;
  final double userRating;
  final EdgeInsets padding;

  const CustomTabSwitcher({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.userRating,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color selectedColor = getInterpolatedColor(userRating);
    Color unselectedColor = Colors.grey;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.map((tab) {
          int index = tabs.indexOf(tab);
          bool isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: isSelected ? null : () => onTabChanged(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 5),
                Text(
                  tab,
                  style: AppColors.topStyle.copyWith(
                    color: isSelected ? selectedColor : unselectedColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  width: isSelected ? 60 : 0,
                  color: isSelected ? selectedColor : Colors.transparent,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
