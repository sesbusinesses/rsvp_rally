import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/models/colors.dart';

class ProfileEditor extends StatefulWidget {
  final String username;

  const ProfileEditor({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _ProfileEditorState createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final ImagePicker _picker = ImagePicker();
  String? _profilePicBase64;
  String _firstName = '';
  String _lastName = '';
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      String? profilePic = await pullProfilePicture(widget.username);
      String? fullName = await getFullName(widget.username);
      double? rating = await getUserRating(widget.username);
      setState(() {
        _profilePicBase64 = profilePic;
        if (fullName != null) {
          var names = fullName.split(' ');
          _firstName = names.isNotEmpty ? names[0] : '';
          _lastName = names.length > 1 ? names[1] : '';
        }
        _rating = rating ?? 0.0;
      });
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        String base64Image = base64Encode(await file.readAsBytes());
        await pushProfilePicture(widget.username, base64Image);
        setState(() {
          _profilePicBase64 = base64Image;
        });
      }
    } catch (e) {
      print('Error changing profile picture: $e');
    }
  }

  String getEmoji(double rating) {
    if (rating <= 0.2) return '😡'; // Mad
    if (rating <= 0.4) return '😢'; // Sad
    if (rating <= 0.6) return '😐'; // Straight face
    if (rating <= 0.8) return '😊'; // Smiling
    return '🤩'; // Joyful
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
      width: screenSize.width * 0.85,
      height: 200, // Adjusted height for better aesthetics
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.light, // Dark background color
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: getInterpolatedColor(_rating),
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
          Stack(
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePicBase64 != null
                        ? MemoryImage(base64Decode(_profilePicBase64!))
                        : null,
                    child: _profilePicBase64 == null
                        ? Icon(Icons.add, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              if (_profilePicBase64 != null)
                Positioned(
                  bottom: 5,  // Adjusted for smaller CircleAvatar
                  right: -5,  // Adjusted for smaller CircleAvatar
                  child: CircleAvatar(
                    radius: 20,  // Smaller radius
                    backgroundColor: Colors.transparent,
                    child: Text(
                      getEmoji(_rating),
                      style: TextStyle(fontSize: 30),  // Larger font size
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            _firstName + ' ' + _lastName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.username,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}