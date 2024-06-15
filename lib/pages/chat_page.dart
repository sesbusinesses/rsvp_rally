import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class ChatPage extends StatefulWidget {
  final String eventID;
  final double rating;
  final String username;

  const ChatPage({
    Key? key,
    required this.eventID,
    required this.rating,
    required this.username,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(widget.eventID)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(child: Text('No messages yet.'));
                      }

                      var messages = snapshot.data!['Messages'] as List<dynamic>;
                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 60), // Adjust padding to avoid overlap with bottom nav
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var messageEntry = Map<String, dynamic>.from(messages[index]);
                          var entry = messageEntry.entries.first;
                          bool isPhoto = entry.value is String && entry.value.toString().startsWith('data:image');
                          return MessageBubble(
                            message: entry.value,
                            isMe: entry.key == widget.username,
                            username: entry.key,
                            isPhoto: isPhoto,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInputArea(),
                SizedBox(height: 60),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNav(
                rating: widget.rating,
                eventID: widget.eventID,
                username: widget.username,
                selectedIndex: 2,
              ),
            ),
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
          IconButton(
            icon: Icon(Icons.photo, color: getInterpolatedColor(widget.rating)),
            onPressed: _pickAndSendPhoto,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: getInterpolatedColor(widget.rating)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: getInterpolatedColor(widget.rating)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      await sendMessage(widget.eventID, widget.username, _controller.text);
      _controller.clear();
    }
  }

  void _pickAndSendPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await sendMessageWithPhotoBase64(widget.eventID, widget.username, image);
      }
    } catch (e) {
      developer.log('Error picking or sending photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking or sending photo: $e')),
      );
    }
  }
}
