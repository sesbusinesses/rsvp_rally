import 'package:flutter/material.dart';

class GroupAvailabilitySelector extends StatelessWidget {
  final bool isEditable;
  final Map<String, Map<String, List<String>>> availability;
  final List<String> days;
  final List<String> times;
  final String username;
  final Function(String, String, bool) onUpdateAvailability;

  const GroupAvailabilitySelector({
    super.key,
    required this.isEditable,
    required this.availability,
    required this.days,
    required this.times,
    required this.username,
    required this.onUpdateAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cellWidth = screenSize.width / (days.length + 1);
    final cellHeight = screenSize.height / (times.length + 15);

    return GestureDetector(
      onPanStart: (details) {
        if (isEditable) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset localPosition = box.globalToLocal(details.globalPosition);
          int dayIndex = (localPosition.dx / cellWidth).floor() - 1;
          int timeIndex = (localPosition.dy / cellHeight).floor() - 1;

          if (dayIndex >= 0 &&
              dayIndex < days.length &&
              timeIndex >= 0 &&
              timeIndex < times.length) {
            bool isSelected = availability[days[dayIndex]]![times[timeIndex]]!
                .contains(username);
            onUpdateAvailability(days[dayIndex], times[timeIndex], !isSelected);
          }
        }
      },
      onPanUpdate: (details) {
        if (isEditable) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset localPosition = box.globalToLocal(details.globalPosition);
          int dayIndex = (localPosition.dx / cellWidth).floor() - 1;
          int timeIndex = (localPosition.dy / cellHeight).floor() - 1;

          if (dayIndex >= 0 &&
              dayIndex < days.length &&
              timeIndex >= 0 &&
              timeIndex < times.length) {
            bool isSelected = availability[days[dayIndex]]![times[timeIndex]]!
                .contains(username);
            onUpdateAvailability(days[dayIndex], times[timeIndex], !isSelected);
          }
        }
      },
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: cellWidth, height: cellHeight),
              ...days.map((day) => Container(
                    width: cellWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    child: Text(day,
                        style: Theme.of(context).textTheme.titleMedium),
                  ))
            ],
          ),
          ...times.map((time) => Row(
                children: [
                  Container(
                    width: cellWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    child: Text(time,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  ...days.map((day) => GestureDetector(
                        onTap: () {
                          if (isEditable) {
                            bool isSelected =
                                availability[day]![time]!.contains(username);
                            onUpdateAvailability(day, time, !isSelected);
                          }
                        },
                        child: Container(
                          width: cellWidth,
                          height: cellHeight,
                          alignment: Alignment.center,
                          color: availability[day]![time]!.contains(username)
                              ? Colors.green
                              : Colors.blue[
                                  100 * (availability[day]![time]!.length + 1)],
                          child: Text('${availability[day]![time]!.length}'),
                        ),
                      ))
                ],
              ))
        ],
      ),
    );
  }
}
