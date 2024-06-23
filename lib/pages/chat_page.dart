import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/widgets/bottomnav.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
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

                      var data = snapshot.data?.data() as Map<String, dynamic>?;
                      if (data == null) {
                        return Center(child: Text('No data available for this chat.'));
                      }

                      var messages = data['Messages'] as List<dynamic>? ?? [];
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
                SizedBox(height: 50),
              ],
            ),
            Positioned(
              bottom: -10, // Adjusted to keep the BottomNav 20 pixels above the bottom
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
            child: WideTextBox(
              hintText: 'Type a message',
              controller: _controller,
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
        final imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          // Convert to PNG or JPEG
          List<int> encodedBytes;
          String mimeType;

          // Convert to JPEG by default for all formats, including HEIC
          encodedBytes = img.encodeJpg(decodedImage);
          mimeType = 'image/jpeg';

          final base64Image = base64Encode(encodedBytes);
          await sendMessage(widget.eventID, widget.username, 'data:$mimeType;base64,$base64Image');
        } else {
          developer.log('Error decoding image');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error decoding image')),
          );
        }
      }
    } catch (e) {
      developer.log('Error picking or sending photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking or sending photo: $e')),
      );
    }
  }
}
