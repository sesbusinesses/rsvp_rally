import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/pages/feed_chat.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';

class ChatOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> chat;
  final String postId;
  final String user;
  final String imageUrl;
  final String description;
  final String viewerUsername;

  const ChatOverlay({
    Key? key,
    required this.chat,
    required this.postId,
    required this.user,
    required this.imageUrl,
    required this.description,
    required this.viewerUsername,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // "V" button to close the overlay
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: IconButton(
              icon: const Icon(Icons.expand_more, size: 30, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: chat.length,
              itemBuilder: (context, index) {
                var message = chat[index];
                return MessageBubble(
                  message: message['message'],
                  isMe: message['username'] == viewerUsername,
                  username: message['username'],
                  viewerUsername: viewerUsername,
                );
              },
            ),
          ),
          _buildMessageInputArea(context),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    Future<void> _sendMessage() async {
      if (_controller.text.isNotEmpty) {
        final newMessage = {
          'username': user,
          'message': _controller.text,
        };
        chat.add(newMessage);

        await FirebaseFirestore.instance
            .collection('Feeds')
            .doc(postId)
            .update({
          'chat': FieldValue.arrayUnion([newMessage]),
        });

        _controller.clear();
      }
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
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
                fillColor: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}