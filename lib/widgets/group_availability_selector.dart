import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupAvailabilitySelector extends StatefulWidget {
  final bool isEditable;
  final String groupID;
  final String? username;

  const GroupAvailabilitySelector({
    super.key,
    required this.isEditable,
    required this.groupID,
    this.username,
  });

  @override
  _GroupAvailabilitySelectorState createState() =>
      _GroupAvailabilitySelectorState();
}

class _GroupAvailabilitySelectorState extends State<GroupAvailabilitySelector> {
  String groupName = "Loading...";
  Map<String, Map<String, List<String>>> availability = {};
  final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<String> times = [
    "12:00 AM",
    "12:30 AM",
    "1:00 AM",
    "1:30 AM",
    "2:00 AM",
    "2:30 AM",
    "3:00 AM",
    "3:30 AM",
    "4:00 AM",
    "4:30 AM",
    "5:00 AM",
    "5:30 AM",
    "6:00 AM",
    "6:30 AM",
    "7:00 AM",
    "7:30 AM",
    "8:00 AM",
    "8:30 AM",
    "9:00 AM",
    "9:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "1:00 PM",
    "1:30 PM",
    "2:00 PM",
    "2:30 PM",
    "3:00 PM",
    "3:30 PM",
    "4:00 PM",
    "4:30 PM",
    "5:00 PM",
    "5:30 PM",
    "6:00 PM",
    "6:30 PM",
    "7:00 PM",
    "7:30 PM",
    "8:00 PM",
    "8:30 PM",
    "9:00 PM",
    "9:30 PM",
    "10:00 PM",
    "10:30 PM",
    "11:00 PM",
    "11:30 PM"
  ];
  bool isDragging = false;
  bool addMode = true;
  Set<String> visitedCells = {};

  @override
  void initState() {
    super.initState();
    fetchGroupName();
    initializeAvailability();
    fetchAvailability();
  }

  Future<void> fetchGroupName() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .get();

      if (groupDoc.exists) {
        setState(() {
          groupName = groupDoc['Name'] ?? "Group Availability";
        });
      }
    } catch (e) {
      print('Error fetching group name: $e');
    }
  }

  void initializeAvailability() {
    for (var day in days) {
      availability[day] = {};
      for (var time in times) {
        availability[day]![time] = [];
      }
    }
  }

  Future<void> fetchAvailability() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .collection(widget.isEditable
              ? 'UpcomingAvailability'
              : 'CurrentAvailability')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String day = data['day'];
          String time = data['time'];
          List<String> users = List<String>.from(data['users'] ?? []);

          setState(() {
            availability[day]![time] = users;
          });
        }
      }
    } catch (e) {
      print('Error fetching availability: $e');
    }
  }

  void updateAvailability(String day, String time, bool selected) {
    if (!widget.isEditable || widget.username == null) return;

    setState(() {
      if (selected) {
        if (!availability[day]![time]!.contains(widget.username)) {
          availability[day]![time]!.add(widget.username!);
        }
      } else {
        availability[day]![time]!.remove(widget.username);
      }
    });

    FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupID)
        .collection('UpcomingAvailability')
        .doc('${widget.username}-$day-$time')
        .set({
      'day': day,
      'time': time,
      'username': widget.username,
      'users': availability[day]![time]!
    });
  }

  void toggleAvailability(String day, String time) {
    if (!widget.isEditable || widget.username == null) return;

    bool isSelected = availability[day]![time]!.contains(widget.username);
    updateAvailability(day, time, !isSelected);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cellWidth = screenSize.width / (days.length + 1);
    final cellHeight = screenSize.height / (times.length + 15);

    return GestureDetector(
      onPanStart: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        int dayIndex = (localPosition.dx / cellWidth).floor() - 1;
        int timeIndex = (localPosition.dy / cellHeight).floor() - 1;

        if (dayIndex >= 0 &&
            dayIndex < days.length &&
            timeIndex >= 0 &&
            timeIndex < times.length) {
          setState(() {
            isDragging = true;
            visitedCells.clear();
            addMode = !availability[days[dayIndex]]![times[timeIndex]]!
                .contains(widget.username);
          });
        }
      },
      onPanUpdate: (details) {
        if (isDragging) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset localPosition = box.globalToLocal(details.globalPosition);
          int dayIndex = (localPosition.dx / cellWidth).floor() - 1;
          int timeIndex = (localPosition.dy / cellHeight).floor() - 1;

          if (dayIndex >= 0 &&
              dayIndex < days.length &&
              timeIndex >= 0 &&
              timeIndex < times.length) {
            String cellKey = '${days[dayIndex]}-${times[timeIndex]}';
            if (!visitedCells.contains(cellKey)) {
              visitedCells.add(cellKey);
              toggleAvailability(days[dayIndex], times[timeIndex]);
            }
          }
        }
      },
      onPanEnd: (details) {
        setState(() {
          isDragging = false;
        });
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
                          if (widget.isEditable) {
                            toggleAvailability(day, time);
                          }
                        },
                        child: Container(
                          width: cellWidth,
                          height: cellHeight,
                          alignment: Alignment.center,
                          color: availability[day]![time]!
                                  .contains(widget.username)
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
