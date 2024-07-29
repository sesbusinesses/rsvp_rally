import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/widgets/message_bubble.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;

class ChatPage extends StatefulWidget {
  final String eventID;
  final double rating;
  final String username;
  final bool isGroup;

  const ChatPage({
    super.key,
    required this.eventID,
    required this.rating,
    required this.username,
    this.isGroup = false,
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

  Future<String> isComing(String eventID, String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      // Fetch the essential polls for the event
      QuerySnapshot essentialPollsSnapshot = await firestore
          .collection('Events')
          .doc(eventID)
          .collection('EssentialPolls')
          .get();

      bool hasRespondedYes = false;
      bool hasRespondedNo = true; // Assume 'No' until proven otherwise

      for (var doc in essentialPollsSnapshot.docs) {
        Map<String, dynamic> pollData = doc.data() as Map<String, dynamic>;

        if (pollData['Question'].startsWith('RSVP for')) {
          // Check if the user has responded 'Yes'
          if (pollData['Yes'] != null && pollData['Yes'].contains(username)) {
            hasRespondedYes = true;
            hasRespondedNo = false; // User has responded 'Yes', so not all 'No'
            break; // No need to check further if 'Yes' is found
          }
          // Check if the user has responded 'No'
          if (pollData['No'] != null && pollData['No'].containsKey(username)) {
            // Continue checking other polls
          } else {
            hasRespondedNo = false; // User has not responded 'No' to this poll
          }
        }
      }

      if (hasRespondedYes) return 'yes';
      if (hasRespondedNo) {
        return 'no'; // Return 'no' if no 'Yes' was found and at least one 'No' was found
      }
      return 'maybe'; // Default response if no 'Yes' and no 'No' was found
    } catch (e) {
      log("Error fetching event or processing data: $e");
      return 'maybe'; // Default response in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(eventName, style: AppColors.topStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[200], // Light grey background
                    child: rsvpStatus == 'yes' || widget.isGroup
                        ? StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Chats')
                                .doc(widget.eventID)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child:
                                        CupertinoActivityIndicator(radius: 15));
                              }

                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Center(
                                    child: Text('No messages yet.',
                                        style: AppColors.bodyStyle));
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
                                  var messageEntry = Map<String, dynamic>.from(
                                      messages[index]);
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
                                    viewerUsername: widget.username,
                                  );
                                },
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'RSVP \'Yes\' to access the chat',
                              style: AppColors.bodyStyle,
                            ),
                          ),
                  ),
                ),
                if (rsvpStatus == 'yes' || widget.isGroup)
                  _buildMessageInputArea(),
              ],
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
              canGrow: true,
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
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        List<int> imageBytes = await file.readAsBytes();
        print('Image size: ${imageBytes.length} bytes');

        // Resize the image if it is too large
        if (imageBytes.length > 1000000) {
          img.Image? originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            if (imageBytes.sublist(0, 6).every((byte) =>
                [0x47, 0x49, 0x46, 0x38, 0x39, 0x61].contains(byte))) {
              // Handle GIF
              img.GifDecoder gifDecoder = img.GifDecoder();
              img.Animation originalGif =
                  gifDecoder.decodeAnimation(imageBytes)!;
              img.Animation resizedGif = img.Animation();

              double reductionFactor = math.sqrt(1000000 / imageBytes.length);
              for (var frame in originalGif.frames) {
                int newWidth = (frame.width * reductionFactor).toInt();
                int newHeight = (frame.height * reductionFactor).toInt();
                img.Image resizedFrame =
                    img.copyResize(frame, width: newWidth, height: newHeight);
                resizedGif.addFrame(resizedFrame);
              }
              var encodedGif = img.encodeGifAnimation(resizedGif);
              if (encodedGif != null) {
                imageBytes = encodedGif;
              }
            } else {
              // Handle static images
              double reductionFactor = math.sqrt(1000000 / imageBytes.length);
              int newWidth = (originalImage.width * reductionFactor).toInt();
              int newHeight = (originalImage.height * reductionFactor).toInt();

              img.Image resizedImage = img.copyResize(originalImage,
                  width: newWidth, height: newHeight);

              // Adjust the quality parameter to reduce file size
              int jpegQuality =
                  75; // You can adjust this value between 0 and 100
              imageBytes = img.encodeJpg(resizedImage, quality: jpegQuality);
            }
            print('Resized image size: ${imageBytes.length} bytes');
          }
        }

        String base64Image = base64Encode(imageBytes);

        await sendMessage(
            widget.eventID,
            widget.username,
            'data:image/${imageBytes.sublist(0, 6).every((byte) => [
                  0x47,
                  0x49,
                  0x46,
                  0x38,
                  0x39,
                  0x61
                ].contains(byte)) ? "gif" : "jpeg"};base64,$base64Image');
        _scrollToBottom();
      }
    } catch (e) {
      developer.log('Error picking or sending photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking or sending photo: $e',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
}
