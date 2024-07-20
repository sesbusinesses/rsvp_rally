import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/route_observer.dart';
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

class _MainPageViewState extends State<MainPageView> with RouteAware {
  late PageController _pageController;
  int _selectedIndex = 1; // Set initial index to 1 to start at EventPage
  late Future<double?> userRatingFuture;
  late Future<DocumentSnapshot> inboxFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
    );
    userRatingFuture = getUserRating(widget.username);
    inboxFuture = getInboxData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload the data whenever MainPageView is revisited
    setState(() {
      userRatingFuture = getUserRating(widget.username);
      inboxFuture = getInboxData();
    });
  }

  Future<DocumentSnapshot> getInboxData() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.username)
        .get();
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

  void _reloadInboxData() {
    setState(() {
      inboxFuture = getInboxData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<double?>(
          future: userRatingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }
            if (snapshot.hasError) {
              return const Text('Error loading rating');
            }
            double userRating = snapshot.data ?? 0;
            return CustomTabSwitcher(
              tabs: const ['Groups', 'Events', 'My Feed'],
              selectedIndex: _selectedIndex,
              onTabChanged: _onTabChanged,
              userRating: userRating,
              padding: const EdgeInsets.only(top: 8.0),
            );
          },
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: FutureBuilder<DocumentSnapshot>(
          future: inboxFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(left: 10, top: 10),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.grey,
                  size: 50,
                ),
              );
            } else if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.only(left: 10, top: 10),
                child: Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 50,
                ),
              );
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.only(left: 10, top: 10),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.grey,
                  size: 50,
                ),
              );
            } else {
              DocumentSnapshot hostDoc = snapshot.data!;
              bool newMessages = hostDoc['NewMessages'] ?? false;
              return ViewInboxButton(
                username: widget.username,
                userRating: snapshot.data!['Rating'] ?? 0.0,
                newMessages: newMessages,
                onInboxOpened: _reloadInboxData,
              );
            }
          },
        ),
        actions: <Widget>[
          FutureBuilder<double?>(
            future: userRatingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              if (snapshot.hasError) {
                return const Text('Error');
              }
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
            return const Center(
                child: CupertinoActivityIndicator(
              radius: 15,
            ));
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
              EventPage(username: widget.username, userRating: userRating),
              FeedPage(username: widget.username, userRating: userRating),
            ],
          );
        },
      ),
    );
  }
}
