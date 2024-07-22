import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_availability_selector.dart';

class GroupCurrentAvailabilityPage extends StatefulWidget {
  final String groupID;

  const GroupCurrentAvailabilityPage({
    super.key,
    required this.groupID,
  });

  @override
  _GroupCurrentAvailabilityPageState createState() =>
      _GroupCurrentAvailabilityPageState();
}

class _GroupCurrentAvailabilityPageState
    extends State<GroupCurrentAvailabilityPage> {
  String groupName = "Current Week's Availability";
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

  @override
  void initState() {
    super.initState();
    fetchGroupName();
    initializeAvailability();
    fetchGroupAvailability();
  }

  Future<void> fetchGroupName() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .get();

      if (groupDoc.exists) {
        setState(() {
          groupName = groupDoc['Name'] ?? "Current Week's Availability";
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

  Future<void> fetchGroupAvailability() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(widget.groupID)
          .collection('CurrentAvailability')
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

  void onUpdateAvailability(String day, String time, bool selected) {
    // This function won't do anything for the current availability page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName, style: AppColors.topStyle),
      ),
      body: GroupAvailabilitySelector(
        isEditable: false,
        availability: availability,
        days: days,
        times: times,
        username: '', // Not needed for the current availability page
        onUpdateAvailability: onUpdateAvailability,
      ),
    );
  }
}
