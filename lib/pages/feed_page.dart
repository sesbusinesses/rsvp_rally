import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/feed_card.dart';
import 'package:rsvp_rally/pages/create_feed.dart';

class FeedPage extends StatefulWidget {
  final String username;

  const FeedPage({required this.username, Key? key}) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<String>> friendsFuture;

  @override
  void initState() {
    super.initState();
    friendsFuture = getUserFriends(widget.username);
  }

  Future<List<String>> getUserFriends(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<String> friends = [];

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();

      if (userDoc.exists) {
        friends = List.from(userDoc.get('Friends') ?? []);
      }
    } catch (e) {
      print('Error fetching user friends: $e');
    }

    return friends;
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('Feeds').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(postId);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No friends found'));
          }

          List<String> friends = snapshot.data!;
          friends.add(widget.username); // Include the user's own posts

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('Feeds')
                .where('user', whereIn: friends)
                .orderBy('timestamp', descending: true) // Order by timestamp
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> feedSnapshot) {
              if (feedSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!feedSnapshot.hasData || feedSnapshot.data!.docs.isEmpty) {
                return Center(child: Text('No feeds available'));
              }
              final feeds = feedSnapshot.data!.docs;

              return ListView.builder(
                itemCount: feeds.length,
                itemBuilder: (context, index) {
                  var feedData = feeds[index];
                  bool isUserPost = feedData['user'] == widget.username;
                  return FeedCard(
                    imageUrl: feedData['imageUrl'],
                    description: feedData['description'],
                    user: feedData['user'],
                    likes: List<String>.from(feedData['likes']),
                    chat: List<Map<String, dynamic>>.from(feedData['chat']),
                    postId: feedData.id, // Pass the post ID to the FeedCard
                    isUserPost: isUserPost, // Indicate if this is the user's post
                    onDelete: isUserPost
                        ? () => _confirmDeletePost(feedData.id)
                        : null, // Pass delete callback if this is the user's post
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateFeedPage(username: widget.username),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
