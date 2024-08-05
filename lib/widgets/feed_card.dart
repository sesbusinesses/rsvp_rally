import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/pages/feed_chat.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';

class FeedCard extends StatefulWidget {
  final String imageUrl;
  final String description;
  final String user;
  final List<String> likes;
  final List<Map<String, dynamic>> chat;
  final String postId;
  final bool isUserPost;
  final bool showDeleteButton;
  final VoidCallback? onDelete;
  final String username;

  const FeedCard({
    required this.imageUrl,
    required this.description,
    required this.user,
    required this.likes,
    required this.chat,
    required this.postId,
    required this.isUserPost,
    required this.username,
    this.onDelete,
    this.showDeleteButton = true,
    super.key,
  });

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool isLiked = false;
  String? fullName;
  double? userRating;
  String? profilePicBase64;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(widget.username);
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    fullName = await getFullName(widget.user);
    userRating = await getUserRating(widget.user);
    profilePicBase64 = await pullProfilePicture(widget.user);
    if (mounted) {
      setState(() {});
    }
  }

  void toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        widget.likes.add(widget.username);
      } else {
        widget.likes.removeWhere((like) => like == widget.username);
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('Feeds')
          .doc(widget.postId)
          .update({
        'likes': widget.likes,
      });
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: getInterpolatedColor(userRating ?? 0),
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style:
                      TextStyle(color: getInterpolatedColor(userRating ?? 0))),
            ),
            TextButton(
              onPressed: () {
                widget.onDelete?.call();
                Navigator.of(context).pop();
              },
              child: Text('Delete',
                  style:
                      TextStyle(color: getInterpolatedColor(userRating ?? 0))),
            ),
          ],
        );
      },
    );
  }

  void _showChatOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.67, // Overlay covers bottom 2/3 of the screen
        child: ChatOverlay(
          chat: widget.chat,
          postId: widget.postId,
          user: widget.user,
          imageUrl: widget.imageUrl,
          description: widget.description,
          viewerUsername: widget.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userRating == null) {
      return Container(); // Show nothing until the rating is loaded
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 35),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white, // Set card color to white
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: getInterpolatedColor(userRating!)
                  .withOpacity(0.3), // Soft shadow with interpolated color
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: profilePicBase64 != null
                        ? MemoryImage(base64Decode(profilePicBase64!))
                        : null,
                    child: profilePicBase64 == null
                        ? const Icon(Icons.person, size: 20, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    fullName ?? 'Loading...',
                    style: AppColors.titleStyle,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
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
            // Move heart and chat icons closer to the image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  if (widget.likes.isNotEmpty)
                    Text(
                      widget.likes.length.toString(),
                      style: TextStyle(
                        color: isLiked ? Colors.red : AppColors.dark,
                        fontSize: 12, // Smaller font size
                      ),
                    ),
                  IconButton(
                    iconSize: 18, // Smaller icon size
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppColors.dark,
                    ),
                    onPressed: toggleLike,
                  ),
                  if (widget.chat.isNotEmpty)
                    Text(
                      widget.chat.length.toString(),
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 12, // Smaller font size
                      ),
                    ),
                  IconButton(
                    iconSize: 18, // Smaller icon size
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.dark),
                    onPressed: () => _showChatOverlay(context), // Use the overlay method
                  ),
                  const Spacer(),
                  // Delete button for the user's post
                  if (widget.isUserPost && widget.showDeleteButton)
                    IconButton(
                      iconSize: 18, // Smaller icon size
                      icon: Icon(Icons.delete_outline, color: AppColors.dark),
                      onPressed: () => _showDeleteConfirmationDialog(context),
                      color: getInterpolatedColor(userRating!),
                    ),
                ],
              ),
            ),
            // Move description closer to the heart/chat icons and add padding below
            if (widget.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    15, 0, 15, 30), // Padding adjusted for spacing
                child: Text(
                  widget.description,
                  style: AppColors.bodyStyle.copyWith(
                    color: AppColors.dark,
                    fontSize: 12, // Smaller font size
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
