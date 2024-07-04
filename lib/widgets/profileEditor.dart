import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:rsvp_rally/models/database_puller.dart';
import 'package:rsvp_rally/models/database_pusher.dart';
import 'package:rsvp_rally/models/colors.dart';

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
        List<int> imageBytes = await file.readAsBytes();

        // Resize the image if it is too large
        if (imageBytes.length > 10000) {
          // Example threshold: 1MB
          img.Image? originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            // Calculate the reduction factor to keep the size under 1MB
            double reductionFactor = math.sqrt(10000 / imageBytes.length);
            img.Image resizedImage = img.copyResize(originalImage,
                width: (originalImage.width * reductionFactor).toInt());
            imageBytes = img.encodeJpg(resizedImage);
          }
        }

        String base64Image = base64Encode(imageBytes);
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
    if (rating <= 0.25) return '😡'; // Mad
    if (rating <= 0.5) return '😕'; // Confused
    if (rating <= 0.75) return '😐'; // Straight face
    return '😊'; // Joyful
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
                      getEmoji(_rating),
                      style: const TextStyle(fontSize: 30), // Larger font size
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$_firstName $_lastName',
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
}
