import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_pusher.dart';

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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading profile data'),
          );
        } else if (snapshot.hasData) {
          var profileData = snapshot.data!;
          String? profilePicBase64 = profileData['profilePicBase64'];
          String firstName = profileData['firstName'];
          String lastName = profileData['lastName'];
          double rating = profileData['rating'];

          return Container(
            width: screenSize.width * 0.85,
            height: 200, // Adjusted height for better aesthetics
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePicture(
                  username: widget.username,
                  profilePicBase64: profilePicBase64,
                  rating: rating,
                ),
                const SizedBox(height: 10),
                Text(
                  '$firstName $lastName',
                  style: AppColors.titleStyle,
                ),
                Text(
                  widget.username,
                  style: AppColors.usernameStyle,
                ),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }
}

class ProfilePicture extends StatefulWidget {
  final String username;
  final String? profilePicBase64;
  final double rating;

  const ProfilePicture({
    super.key,
    required this.username,
    this.profilePicBase64,
    required this.rating,
  });

  @override
  _ProfilePictureState createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  final ImagePicker _picker = ImagePicker();
  String? _profilePicBase64;

  @override
  void initState() {
    super.initState();
    _profilePicBase64 = widget.profilePicBase64;
  }

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      if (imageBytes.length > 100000) {
        img.Image? originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          double reductionFactor = math.sqrt(100000 / imageBytes.length);
          int newWidth = (originalImage.width * reductionFactor).toInt();
          int newHeight = (originalImage.height * reductionFactor).toInt();

          img.Image resizedImage =
              img.copyResize(originalImage, width: newWidth, height: newHeight);

          // Adjust the quality parameter to reduce file size
          int jpegQuality = 75; // You can adjust this value between 0 and 100
          imageBytes = img.encodeJpg(resizedImage, quality: jpegQuality);
          print('Resized image size: ${imageBytes.length} bytes');
        }
      }

      pushProfilePicture(widget.username, base64Encode(imageBytes));

      setState(() {
        _profilePicBase64 = base64Encode(imageBytes);
      });
    }
  }

  Future<void> pushProfilePicture(String username, String base64Image) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userRef = firestore.collection('Users').doc(username);

    try {
      await userRef.update({'ProfilePic': base64Image});
      print('Profile picture updated successfully');
    } catch (e) {
      print('Error updating profile picture: $e');
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
    return Stack(
      children: [
        GestureDetector(
          onTap: _changeProfilePicture,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _profilePicBase64 != null
                  ? MemoryImage(base64Decode(_profilePicBase64!))
                  : null,
              child: _profilePicBase64 == null
                  ? const Icon(Icons.add, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        if (_profilePicBase64 != null)
          Positioned(
            bottom: 5, // Adjusted for smaller CircleAvatar
            right: -5, // Adjusted for smaller CircleAvatar
            child: CircleAvatar(
              radius: 20, // Smaller radius
              backgroundColor: Colors.transparent,
              child: Text(
                getEmoji(widget.rating),
                style: const TextStyle(fontSize: 30), // Larger font size
              ),
            ),
          ),
      ],
    );
  }
}
