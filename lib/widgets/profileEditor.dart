import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:image_cropper/image_cropper.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/profilePic.dart';

class ProfileEditor extends StatefulWidget {
  final String username;

  const ProfileEditor({
    super.key,
    required this.username,
  });

  @override
  _ProfileEditorState createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late Future<Map<String, dynamic>> _profileData;

  @override
  void initState() {
    super.initState();
    _profileData = _loadProfileData();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    try {
      String? profilePic = await pullProfilePicture(widget.username);
      String? fullName = await getFullName(widget.username);
      double? rating = await getUserRating(widget.username);

      var names = fullName?.split(' ') ?? [];
      return {
        'profilePicBase64': profilePic,
        'firstName': names.isNotEmpty ? names[0] : '',
        'lastName': names.length > 1 ? names[1] : '',
        'rating': rating ?? 0.0,
      };
    } catch (e) {
      print('Error loading profile data: $e');
      return {};
    }
  }

  Future<String?> pullProfilePicture(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();
      if (!userDoc.exists) {
        print("No user found with username $username");
        return null;
      }
      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('ProfilePic')) {
        print("Field 'ProfilePic' does not exist for user $username");
        return null;
      }
      return data['ProfilePic'] as String?;
    } catch (e) {
      print('Error fetching profile picture: $e');
      return null;
    }
  }

  Future<String?> getFullName(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();
      if (!userDoc.exists) {
        print("No user found with username $username");
        return null;
      }
      String firstName = userDoc.get('FirstName') ?? '';
      String lastName = userDoc.get('LastName') ?? '';
      String fullName = '$firstName $lastName'.trim();
      return fullName.isNotEmpty ? fullName : null;
    } catch (e) {
      print("Error fetching full name: $e");
      return null;
    }
  }

  Future<double?> getUserRating(String username) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(username).get();
      if (!userDoc.exists) {
        print("No user found with username $username");
        return null;
      }
      double? rating = userDoc.get('Rating');
      return rating;
    } catch (e) {
      print("Error fetching user rating: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileData,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (profileSnapshot.hasError) {
          return const Center(
            child: Text('Error loading profile data'),
          );
        } else if (profileSnapshot.hasData) {
          var profileData = profileSnapshot.data!;
          String? profilePicBase64 = profileData['profilePicBase64'];
          String firstName = profileData['firstName'];
          String lastName = profileData['lastName'];
          double rating = profileData['rating'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Shop')
                .doc('freakText')
                .get(),
            builder: (context, freakSnapshot) {
              if (freakSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (freakSnapshot.hasError) {
                return Center(child: Text('Error loading freak status'));
              } else {
                bool isFreak = false;
                if (freakSnapshot.hasData && freakSnapshot.data != null) {
                  Map<String, dynamic> freakData =
                      freakSnapshot.data!.data() as Map<String, dynamic>;
                  isFreak = freakData[widget.username] == true;
                }

                return Container(
                  width: screenSize.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.light, // Dark background color
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
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfilePicture(
                            username: widget.username,
                            profilePicBase64: profilePicBase64,
                            rating: rating,
                          ),
                          Text(
                            '$firstName $lastName',
                            style: AppColors.titleStyle,
                          ),
                          Text(
                            widget.username,
                            style: AppColors.usernameStyle,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      if (isFreak)
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Text(
                            "𝓯𝓻𝓮𝓪𝓴𝔂",
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: getInterpolatedColor(rating),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
            },
          );
        }
        return Container();
      },
    );
  }
}
