import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';

class GroupAvailabilityPage extends StatefulWidget {
  final String groupID;
  final String username;
  final double userRating;

  const GroupAvailabilityPage(
      {super.key,
      required this.groupID,
      required this.username,
      required this.userRating});

  @override
  _GroupAvailabilityPageState createState() => _GroupAvailabilityPageState();
}

class _GroupAvailabilityPageState extends State<GroupAvailabilityPage> {
  String groupName = "Group Availability";

  @override
  void initState() {
    super.initState();
    fetchGroupName();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName, style: AppColors.topStyle),
      ),
      body: GroupAvailabilitySelector(
        groupID: widget.groupID,
        username: widget.username,
      ),
    );
  }
}

class GroupAvailabilitySelector extends StatefulWidget {
  final String groupID;
  final String username;

  const GroupAvailabilitySelector(
      {super.key, required this.groupID, required this.username});

  @override
  _GroupAvailabilitySelectorState createState() =>
      _GroupAvailabilitySelectorState();
}

class _GroupAvailabilitySelectorState extends State<GroupAvailabilitySelector> {
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

  Map<String, Map<String, List<String>>> availability = {};
  bool isDragging = false;
  Set<String> visitedCells = {};

  @override
  void initState() {
    super.initState();
    initializeAvailability();
    fetchGroupAvailability();
  }

  void initializeAvailability() {
    for (var day in days) {
      availability[day] = {};
      for (var time in times) {
        availability[day]![time] = [];
      }
    }
  }

  Future<void> fetchGroupAvailability() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .collection('Availability')
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
      print('Error fetching group availability: $e');
    }
  }

  void updateAvailability(String day, String time, bool selected) {
    setState(() {
      if (selected) {
        if (!availability[day]![time]!.contains(widget.username)) {
          availability[day]![time]!.add(widget.username);
        }
      } else {
        availability[day]![time]!.remove(widget.username);
      }
    });

    FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupID)
        .collection('Availability')
        .doc('$day-$time')
        .set({'day': day, 'time': time, 'users': availability[day]![time]!});
  }

  void onDragUpdate(String day, String time) {
    String cellKey = '$day-$time';
    if (isDragging && !visitedCells.contains(cellKey)) {
      visitedCells.add(cellKey);
      updateAvailability(day, time, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cellWidth = screenSize.width / (days.length + 1);
    final cellHeight = screenSize.height / (times.length + 15);

    return GestureDetector(
      onPanStart: (_) {
        setState(() {
          isDragging = true;
          visitedCells.clear();
        });
      },
      onPanEnd: (_) {
        setState(() {
          isDragging = false;
        });
      },
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        int dayIndex = (localPosition.dx / cellWidth).floor() - 1;
        int timeIndex = (localPosition.dy / cellHeight).floor() - 1;

        if (dayIndex >= 0 &&
            dayIndex < days.length &&
            timeIndex >= 0 &&
            timeIndex < times.length) {
          onDragUpdate(days[dayIndex], times[timeIndex]);
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
                    child: Text(day, style: AppColors.subtitleStyle),
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
                        style: AppColors.subtitleStyle.copyWith(fontSize: 10)),
                  ),
                  ...days.map((day) => GestureDetector(
                        onTap: () {
                          bool isSelected = availability[day]![time]!
                              .contains(widget.username);
                          updateAvailability(day, time, !isSelected);
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
