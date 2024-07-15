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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Feeds')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var feeds = snapshot.data!.docs;

          return ListView.builder(
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
                },
                username: widget.username,
              );
            },
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
