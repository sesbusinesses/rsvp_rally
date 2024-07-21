import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/group_availability_page.dart';
import 'package:rsvp_rally/pages/group_edit_page.dart';
import 'package:rsvp_rally/pages/group_polls_page.dart';
import 'package:rsvp_rally/widgets/group_bottom_nav.dart';

class GroupPageView extends StatefulWidget {
  final String groupID;
  final String username;
  final double userRating;

  const GroupPageView({
    super.key,
    required this.groupID,
    required this.username,
    required this.userRating,
  });

  @override
  _GroupPageViewState createState() => _GroupPageViewState();
}

class _GroupPageViewState extends State<GroupPageView> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
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

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      GroupAvailabilityPage(
          groupID: widget.groupID,
          username: widget.username,
          userRating: widget.userRating),
      GroupPollsPage(
        groupID: widget.groupID,
        username: widget.username,
        userRating: widget.userRating,
      ),
    ];

    if (isHost) {
      pages.add(GroupEditPage(
        groupID: widget.groupID,
        username: widget.username,
        rating: widget.userRating,
      ));
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: GroupBottomNav(
        groupID: widget.groupID,
        username: widget.username,
        selectedIndex: _selectedIndex,
        pageController: _pageController,
        onPageChanged: _onPageChanged,
        userRating: widget.userRating,
      ),
    );
  }
}
