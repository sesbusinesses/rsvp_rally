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
    super.key,
    required this.message,
    required this.isMe,
    required this.username,
    this.isPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        pullProfilePicture(username), // Fetch profile picture
        getUserRating(username), // Fetch user rating
      ]),
      builder: (context, snapshot) {
        Widget profilePicture;
        double userRating = 0.0;

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            String? profilePictureData = snapshot.data![0];
            double? userRatingData = snapshot.data![1] as double?;
            userRating = userRatingData ?? 0.0;

            profilePicture = CircleAvatar(
              radius: 15,
              backgroundImage: profilePictureData != null
                  ? MemoryImage(base64Decode(profilePictureData))
                  : null,
              child: profilePictureData == null
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            );
          } else {
            profilePicture = const CircleAvatar(
              radius: 15,
              child: Icon(Icons.person, size: 20, color: Colors.grey),
            );
          }
        } else {
          profilePicture = const CircleAvatar(
            radius: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: isMe
                ? 50.0
                : 8.0, // Padding between profile picture and screen edge
            right: isMe
                ? 8.0
                : 50.0, // Padding between profile picture and screen edge
          ),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: profilePicture,
                ),
              Flexible(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: isPhoto
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: getInterpolatedColor(userRating),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft:
                          isMe ? const Radius.circular(15) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(15),
                    ),
                  ),
                  child: isPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft:
                                isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(15),
                          ),
                          child: Image.memory(
                            base64Decode(
                                message.split(',')[1]), // Decode Base64 string
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.red),
                              );
                            },
                          ),
                        )
                      : Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black,
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
