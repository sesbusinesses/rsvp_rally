import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_availability_selector.dart';

class GroupUploadAvailabilityPage extends StatefulWidget {
  final String groupID;
  final String username;

  const GroupUploadAvailabilityPage({
    super.key,
    required this.groupID,
    required this.username,
  });

  @override
  _GroupUploadAvailabilityPageState createState() =>
      _GroupUploadAvailabilityPageState();
}

class _GroupUploadAvailabilityPageState
    extends State<GroupUploadAvailabilityPage> {
  String groupName = "Upload Upcoming Week's Availability";
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
    fetchUserAvailability();
  }

  Future<void> fetchGroupName() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .get();

      if (groupDoc.exists) {
        setState(() {
          groupName = groupDoc['Name'] ?? "Upload Upcoming Week's Availability";
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

  Future<void> fetchUserAvailability() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .collection('UpcomingAvailability')
          .where('username', isEqualTo: widget.username)
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
      print('Error fetching user availability: $e');
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
        .collection('UpcomingAvailability')
        .doc('${widget.username}-$day-$time')
        .set({
      'day': day,
      'time': time,
      'username': widget.username,
      'users': availability[day]![time]!
    });
  }

  void onUpdateAvailability(String day, String time, bool isStart) {
    if (isStart) {
      setState(() {
        isDragging = true;
        visitedCells.clear();
        addMode = !availability[day]![time]!.contains(widget.username);
      });
    } else {
      setState(() {
        isDragging = false;
      });
    }

    if (isDragging &&
        day.isNotEmpty &&
        time.isNotEmpty &&
        !visitedCells.contains('$day-$time')) {
      visitedCells.add('$day-$time');
      updateAvailability(day, time, addMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName, style: AppColors.topStyle),
      ),
      body: GroupAvailabilitySelector(
        isEditable: true,
        availability: availability,
        days: days,
        times: times,
        username: widget.username,
        onUpdateAvailability: onUpdateAvailability,
      ),
    );
  }
}
