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
    super.key,
    required this.eventID,
    required this.rating,
    required this.username,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  String eventName = 'Event Chat'; // Default text
  String rsvpStatus = 'maybe'; // Default RSVP status

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
    fetchEventName();
    checkRSVPStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchEventName() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot eventDoc =
        await firestore.collection('Events').doc(widget.eventID).get();

    if (eventDoc.exists) {
      Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        eventName = data['EventName'] ??
            'Event Details'; // Set the event name or default
      });
    }
  }

  Future<void> checkRSVPStatus() async {
    String status = await isComing(widget.eventID, widget.username);
    setState(() {
      rsvpStatus = status;
    });
  }

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
                  child: rsvpStatus == 'yes'
                      ? StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Chats')
                              .doc(widget.eventID)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const Center(
                                  child: Text('No messages yet.'));
                            }

                            var messages =
                                snapshot.data!['Messages'] as List<dynamic>;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 60),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                var messageEntry =
                                    Map<String, dynamic>.from(messages[index]);
                                var entry = messageEntry.entries.first;
                                bool isPhoto = entry.value is String &&
                                    entry.value
                                        .toString()
                                        .startsWith('data:image');
                                return MessageBubble(
                                  message: entry.value,
                                  isMe: entry.key == widget.username,
                                  username: entry.key,
                                  isPhoto: isPhoto,
                                );
                              },
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'RSVP \'Yes\' to access the chat',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                ),
                if (rsvpStatus == 'yes') _buildMessageInputArea(),
                const SizedBox(height: 50),
              ],
            ),
            Positioned(
              bottom: -10,
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
          await sendMessage(widget.eventID, widget.username,
              'data:$mimeType;base64,$base64Image');
        } else {
          developer.log('Error decoding image');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error decoding image')),
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
}
