import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';

class FeedCard extends StatefulWidget {
  final String imageUrl;
  final String description;
  final String user;
  final List<String> likes;
  final List<Map<String, dynamic>> chat;
  final String postId;
  final bool isUserPost;
  final VoidCallback? onDelete;

  const FeedCard({
    required this.imageUrl,
    required this.description,
    required this.user,
    required this.likes,
    required this.chat,
    required this.postId,
    required this.isUserPost,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(widget.user);
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    // Implement like functionality
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  base64Decode(widget.imageUrl),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: AppColors.bodyStyle,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: toggleLike,
                    ),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline),
                      onPressed: () {
                        // Implement chat functionality
                      },
                    ),
                  ],
                ),
                if (widget.isUserPost)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
