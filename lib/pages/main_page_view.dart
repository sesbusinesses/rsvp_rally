import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/pages/groups_page.dart';
import 'package:rsvp_rally/pages/event_page.dart';
import 'package:rsvp_rally/pages/feed_page.dart';
import 'package:rsvp_rally/widgets/custom_switcher.dart';
import 'package:rsvp_rally/widgets/view_inbox_button.dart';
import 'package:rsvp_rally/widgets/view_friends_button.dart';

class MainPageView extends StatefulWidget {
  final String username;

  const MainPageView({super.key, required this.username});

  @override
  _MainPageViewState createState() => _MainPageViewState();
}

class _MainPageViewState extends State<MainPageView> {
  late PageController _pageController;
  int _selectedIndex = 1; // Set initial index to 1 to start at EventPage
  late Future<double?> userRatingFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        initialPage:
            _selectedIndex); // Initialize PageController with initialPage
    userRatingFuture = getUserRating(widget.username);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<double?>(
          future: userRatingFuture,
          builder: (context, snapshot) {
            double userRating = snapshot.data ?? 0;
            return CustomTabSwitcher(
              tabs: const [
                Icons.group, // Represents groups
                Icons.event, // Represents events
                Icons.feed, // Represents my feed
              ],
              selectedIndex: _selectedIndex,
              onTabChanged: _onTabChanged,
              userRating: userRating,
              padding:
                  const EdgeInsets.only(top: 8.0), // Adjust padding as needed
              iconSize: 24.0, // Adjust the icon size as needed
            );
          },
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: FutureBuilder<double?>(
          future: userRatingFuture,
          builder: (context, snapshot) {
            double userRating = snapshot.data ?? 0;
            return ViewInboxButton(
              username: widget.username,
              userRating: userRating,
            );
          },
        ),
        actions: <Widget>[
          FutureBuilder<double?>(
            future: userRatingFuture,
            builder: (context, snapshot) {
              double userRating = snapshot.data ?? 0;
              return ViewFriendsButton(
                username: widget.username,
                userRating: userRating,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<double?>(
        future: userRatingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          double userRating = snapshot.data ?? 0.0;
          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              GroupsPage(),
              EventPage(username: widget.username),
              FeedPage(username: widget.username, userRating: userRating),
            ],
          );
        },
      ),
    );
  }
}
