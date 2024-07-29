import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rsvp_rally/models/colors.dart';

class GroupAvailabilitySelector extends StatefulWidget {
  final bool isEditable;
  final String groupID;
  final String? username;
  final double userRating;

  const GroupAvailabilitySelector({
    super.key,
    required this.isEditable,
    required this.groupID,
    this.username,
    required this.userRating,
  });

  @override
  _GroupAvailabilitySelectorState createState() =>
      _GroupAvailabilitySelectorState();
}

class _GroupAvailabilitySelectorState extends State<GroupAvailabilitySelector> {
  String groupName = "Loading...";
  Map<String, Map<String, List<String>>> availability = {};
  final List<String> times = [
    "12:00 AM",
    "1:00 AM",
    "2:00 AM",
    "3:00 AM",
    "4:00 AM",
    "5:00 AM",
    "6:00 AM",
    "7:00 AM",
    "8:00 AM",
    "9:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "1:00 PM",
    "2:00 PM",
    "3:00 PM",
    "4:00 PM",
    "5:00 PM",
    "6:00 PM",
    "7:00 PM",
    "8:00 PM",
    "9:00 PM",
    "10:00 PM",
    "11:00 PM"
  ];
  bool isDragging = false;
  bool addMode = true;
  Set<String> visitedCells = {};
  late DateTime startOfWeek;

  @override
  void initState() {
    super.initState();
    fetchGroupName();
    initializeAvailability();
    fetchAvailability().then((_) {
      if (!widget.isEditable) {
        int maxPeople = getMaxAvailability(availability);
        // print('Maximum people available at any time: $maxPeople');
      }
    });
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
    startOfWeek = getStartOfWeek();
    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      availability[dateString] = {};
      for (var time in times) {
        availability[dateString]![time] = [];
      }
    }
  }

  DateTime getStartOfWeek() {
    DateTime now = DateTime.now();
    int weekday = (now.weekday + 6) % 7; // Monday is 0, ..., Sunday is 6
    DateTime startOfWeek = now.subtract(Duration(days: weekday));
    if (widget.isEditable) {
      startOfWeek =
          startOfWeek.add(const Duration(days: 7)); // Start from next week
    }
    // print('Start of week: $startOfWeek');
    return startOfWeek;
  }

  Future<void> fetchAvailability() async {
    try {
      // print('Fetching availability for group isEditable: ${widget.isEditable}');
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .collection('Availability')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          // print(doc.data());
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String date = data['date'];
          String time = data['time'];
          List<String> users = List<String>.from(data['users'] ?? []);

          DateTime parsedDate = DateTime.parse(date);
          if (parsedDate
                  .isAfter(startOfWeek.subtract(const Duration(minutes: 1))) &&
              parsedDate.isBefore(startOfWeek.add(const Duration(days: 6)))) {
            setState(() {
              availability[date] ??= {};
              availability[date]![time] = users;
              // print('Fetched availability for $date $time: $users');
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching availability: $e');
    }
  }

  void updateAvailability(String date, String time, bool selected) {
    if (!widget.isEditable || widget.username == null) return;

    setState(() {
      if (selected) {
        if (!availability[date]![time]!.contains(widget.username)) {
          availability[date]![time]!.add(widget.username!);
        }
      } else {
        print('Removing ${widget.username} from $date at $time');
        availability[date]![time]!.remove(widget.username);
      }
    });

    FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupID)
        .collection('Availability')
        .doc('$date-$time')
        .set({'date': date, 'time': time, 'users': availability[date]![time]!},
            SetOptions(merge: true));
  }

  void toggleAvailability(String date, String time) {
    if (!widget.isEditable || widget.username == null) return;

    bool isSelected = availability[date]![time]!.contains(widget.username);
    updateAvailability(date, time, !isSelected);
  }

  int getMaxAvailability(Map<String, Map<String, List<String>>> availability) {
    int maxPeople = 0;

    availability.forEach((date, times) {
      times.forEach((time, users) {
        if (users.length > maxPeople) {
          maxPeople = users.length;
        }
      });
    });

    return maxPeople;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        double usableWidth =
            box.size.width * 7 / 8; // Assuming 50 pixels are non-selectable
        int dayIndex =
            ((localPosition.dx - box.size.width / 8) / usableWidth * 7).floor();
        int timeIndex =
            (localPosition.dy / box.size.height * (times.length + 1)).floor() -
                1;

        if (dayIndex >= 0 &&
            dayIndex < 7 &&
            timeIndex >= 0 &&
            timeIndex < times.length) {
          String date = availability.keys.elementAt(dayIndex);
          setState(() {
            isDragging = true;
            visitedCells.clear();
            addMode = !availability[date]![times[timeIndex]]!
                .contains(widget.username);
          });
        }
      },
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        double usableWidth =
            box.size.width * 7 / 8; // Adjusting for non-selectable area
        int dayIndex =
            ((localPosition.dx - box.size.width / 8) / usableWidth * 7).floor();
        int timeIndex =
            (localPosition.dy / box.size.height * (times.length + 1)).floor() -
                1;

        if (dayIndex >= 0 &&
            dayIndex < 7 &&
            timeIndex >= 0 &&
            timeIndex < times.length) {
          String date = availability.keys.elementAt(dayIndex);
          String cellKey = '$date-${times[timeIndex]}';
          if (!visitedCells.contains(cellKey)) {
            visitedCells.add(cellKey);
            toggleAvailability(date, times[timeIndex]);
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
              const Expanded(
                child: SizedBox.shrink(),
              ),
              ...availability.keys.map((date) => Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('EEE').format(DateTime.parse(date)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ))
            ],
          ),
          ...times.map((time) => Expanded(
                  child: Row(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(time,
                          style:
                              AppColors.subtitleStyle.copyWith(fontSize: 10)),
                    ),
                  ),
                  ...availability.keys.map((date) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (widget.isEditable) {
                              toggleAvailability(date, time);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black, width: 0.25),
                              color: widget.isEditable
                                  ? (availability[date] != null &&
                                          availability[date]![time] != null &&
                                          availability[date]![time]!
                                              .contains(widget.username)
                                      ? getInterpolatedColor(widget.userRating)
                                      : AppColors.light)
                                  : (availability[date] != null &&
                                          availability[date]![time] != null &&
                                          availability[date]![time]!.isNotEmpty)
                                      ? Color.lerp(
                                          AppColors.light,
                                          getInterpolatedColor(
                                              widget.userRating),
                                          availability[date]![time]!.length /
                                              getMaxAvailability(availability))
                                      : AppColors.light,
                            ),
                            alignment: Alignment.center,
                          ),
                        ),
                      ))
                ],
              )))
        ],
      ),
    );
  }
}
