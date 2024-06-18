import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Import pullProfilePicture
import 'dart:convert';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String username;
  final bool isPhoto;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.username,
    this.isPhoto = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: pullProfilePicture(username), // Fetch profile picture
      builder: (context, snapshot) {
        Widget profilePicture;

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            profilePicture = CircleAvatar(
              radius: 15,
              backgroundImage: MemoryImage(base64Decode(snapshot.data!)),
              child: snapshot.data == null
                  ? Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            );
          } else {
            profilePicture = CircleAvatar(
              radius: 15,
              child: Icon(Icons.person, size: 20, color: Colors.grey),
            );
          }
        } else {
          profilePicture = CircleAvatar(
            radius: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: isMe ? 50.0 : 8.0, // Padding between profile picture and screen edge
            right: isMe ? 8.0 : 50.0, // Padding between profile picture and screen edge
          ),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: profilePicture,
                ),
              Flexible(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: isPhoto ? EdgeInsets.zero : EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: isMe ? getInterpolatedColor(1.0) : getInterpolatedColor(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: isMe ? Radius.circular(15) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : Radius.circular(15),
                    ),
                  ),
                  child: isPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: isMe ? Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : Radius.circular(15),
                          ),
                          child: Image.memory(
                            base64Decode(message.split(',')[1]), // Decode Base64 string
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.red),
                              );
                            },
                          ),
                        )
                      : Text(
                          message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                ),
              ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: profilePicture,
                ),
            ],
          ),
        );
      },
    );
  }
}