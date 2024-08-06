import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/pages/create_feed.dart';
import 'package:rsvp_rally/widgets/create_feed_button.dart';
import 'package:rsvp_rally/widgets/feed_card.dart';

class FeedPage extends StatefulWidget {
  final String username;
  final double userRating;

  const FeedPage({
    super.key,
    required this.username,
    required this.userRating,
  });

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<DocumentSnapshot> feeds = [];
  bool isLoading = true;
  late ScrollController _scrollController;
  late int _lastVisibleItemIndex; // Track the last visible item index

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lastVisibleItemIndex = 0;
    fetchFeeds();
  }

  Future<void> fetchFeeds() async {
    try {
      // Fetch all feeds at once
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Feeds')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        feeds = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle the error appropriately in your app
      print('Error fetching feeds: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return widget.userRating >= 0.75
        ? Scaffold(
            body: isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 15))
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        // Update the last visible item index when scrolling
                        int currentIndex = _scrollController.position.pixels ~/
                            _scrollController.position.maxScrollExtent *
                            feeds.length;
                        _lastVisibleItemIndex = currentIndex;
                      }
                      return false;
                    },
                    child: ListView.builder(
                      key: PageStorageKey('FeedList'),
                      controller: _scrollController,
                      itemCount: feeds.length,
                      itemBuilder: (context, index) {
                        var feed = feeds[index];
                        return FeedCard(
                          key: ValueKey(
                              feed.id), // Ensure each FeedCard has a unique key
                          imageUrls: List<String>.from(feed[
                              'imageUrls']), // Updated to handle multiple images
                          description: feed['description'],
                          user: feed['user'],
                          likes: List<String>.from(feed['likes']),
                          chat: List<Map<String, dynamic>>.from(feed['chat']),
                          postId: feed.id,
                          isUserPost: feed['user'] == widget.username,
                          onDelete: () async {
                            await FirebaseFirestore.instance
                                .collection('Feeds')
                                .doc(feed.id)
                                .delete();
                            setState(() {
                              feeds.removeAt(
                                  index); // Remove the deleted post locally
                            });
                          },
                          username: widget.username,
                        );
                      },
                    ),
                  ),
            floatingActionButton: CreateFeedButton(
              userRating: widget.userRating,
              username: widget.username,
            ),
          )
        : Center(
            child: SizedBox(
            width: screenSize.width * 0.85,
            child: Text(
              'Feed only available for users with a rating of 0.75 or higher.',
              style: AppColors.bodyStyle,
            ),
          ));
  }
}
