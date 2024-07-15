import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    fetchFeeds();
  }

  Future<void> fetchFeeds() async {
    try {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : ListView.builder(
              itemCount: feeds.length,
              itemBuilder: (context, index) {
                var feed = feeds[index];
                return FeedCard(
                  imageUrl: feed['imageUrl'],
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
                    fetchFeeds(); // Refresh the feed after deletion
                  },
                  username: widget.username,
                );
              },
            ),
      floatingActionButton: CreateFeedButton(
        userRating: widget.userRating,
        username: widget.username,
      ),
    );
  }
}
