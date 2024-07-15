import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:rsvp_rally/models/colors.dart';

class UserCard extends StatelessWidget {
  final String username;
  final bool smallVersion;
  final Icon? icon;
  final bool removePadding;
  final bool showUsername;

  const UserCard(
      {super.key,
      required this.username,
      this.smallVersion = false,
      this.removePadding = false,
      this.showUsername = true,
      this.icon});

  Future<Map<String, dynamic>> fetchUserData(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('Users').doc(username).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return {
        'firstName': userData['FirstName'] ?? "",
        'lastName': userData['LastName'] ?? "",
        'profilePicBase64': userData['ProfilePic'],
        'rating': double.tryParse(userData['Rating'].toString()) ?? 0.0,
      };
    } else {
      throw Exception("User not found");
    }
  }

  String getEmoji(double rating) {
    if (rating <= 0.25) return '😡'; // Mad
    if (rating <= 0.5) return '😕'; // Confused
    if (rating <= 0.75) return '😐'; // Straight face
    return '😊'; // Joyful
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserData(username),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading user data'),
          );
        } else if (snapshot.hasData) {
          var userData = snapshot.data!;
          String firstName = userData['firstName'];
          String lastName = userData['lastName'];
          String? profilePicBase64 = userData['profilePicBase64'];
          double rating = userData['rating'];

          return Container(
            width: screenSize.width * 0.85,
            height: smallVersion
                ? 50
                : 80, // Adjusted height for consistency with ProfileEditor
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: removePadding
                ? const EdgeInsets.symmetric(vertical: 0)
                : const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: getInterpolatedColor(rating),
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
            child: Row(
              children: [
                const SizedBox(width: 10), // Space between border and picture
                Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: smallVersion ? 15 : 30,
                        backgroundImage: profilePicBase64 != null
                            ? MemoryImage(base64Decode(profilePicBase64))
                            : null,
                        child: profilePicBase64 == null
                            ? Icon(Icons.add,
                                size: smallVersion ? 15 : 30,
                                color: AppColors.accentDark)
                            : null,
                      ),
                    ),
                    if (profilePicBase64 != null && !smallVersion)
                      Positioned(
                        bottom: -3, // Adjusted for smaller CircleAvatar
                        right: -6, // Adjusted for smaller CircleAvatar
                        child: CircleAvatar(
                          radius: 18, // Smaller radius
                          backgroundColor: Colors.transparent,
                          child: Text(
                            getEmoji(rating),
                            style: const TextStyle(
                                fontSize: 20), // Larger font size
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20), // Space between picture and text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: AppColors.bodyStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showUsername && !smallVersion)
                        Text(username, style: AppColors.usernameStyle),
                    ],
                  ),
                ),
                if (icon != null) icon!,
                if (icon != null) const SizedBox(width: 15),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }
}
