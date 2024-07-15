import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';

class FeedCard extends StatefulWidget {
  final String imageUrl;
  final String description;
  final String user;
  final List<String> likes;
  final List<Map<String, dynamic>> chat;
  final String postId;
  final bool isUserPost;
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
    super.key,
  });

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool isLiked = false;
  String? fullName;
  double userRating = 0.0;
  String? profilePicBase64;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(widget.username);
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    fullName = await getFullName(widget.user);
    userRating = (await getUserRating(widget.user))!;
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
          surfaceTintColor: getInterpolatedColor(userRating),
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: getInterpolatedColor(userRating))),
            ),
            TextButton(
              onPressed: () {
                widget.onDelete?.call();
                Navigator.of(context).pop();
              },
              child: Text('Delete',
                  style: TextStyle(color: getInterpolatedColor(userRating))),
            ),
          ],
        );
      },
    );
  }

  void _showChatPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          postId: widget.postId,
          user: widget.username,
          imageUrl: widget.imageUrl,
          description: widget.description,
          chat: widget.chat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 35),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: getInterpolatedColor(userRating),
            width: AppColors.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.description,
                  style: AppColors.bodyStyle,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.likes.isNotEmpty)
                        Text(
                          widget.likes.length.toString(),
                          style: TextStyle(
                            color: isLiked ? Colors.red : AppColors.dark,
                          ),
                        ),
                      IconButton(
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
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => _showChatPage(context),
                      ),
                    ],
                  ),
                  if (widget.isUserPost)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: getInterpolatedColor(userRating)),
                      onPressed: () => _showDeleteConfirmationDialog(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String postId;
  final String user;
  final String imageUrl;
  final String description;
  final List<Map<String, dynamic>> chat;

  const ChatDetailPage({
    required this.postId,
    required this.user,
    required this.imageUrl,
    required this.description,
    required this.chat,
    super.key,
  });

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> chatMessages = [];

  @override
  void initState() {
    super.initState();
    chatMessages = widget.chat;
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final newMessage = {
        'username': widget.user,
        'message': _controller.text,
      };
      setState(() {
        chatMessages.add(newMessage);
      });

      await FirebaseFirestore.instance
          .collection('Feeds')
          .doc(widget.postId)
          .update({
        'chat': FieldValue.arrayUnion([newMessage]),
      });

      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Chat', style: AppColors.topStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 60),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    var messageEntry = chatMessages[index];
                    return MessageBubble(
                      message: messageEntry['message'],
                      isMe: messageEntry['username'] == widget.user,
                      username: messageEntry['username'],
                    );
                  },
                ),
              ),
            ),
            _buildMessageInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.dark),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
