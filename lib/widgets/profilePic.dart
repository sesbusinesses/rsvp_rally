import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:image_cropper/image_cropper.dart';
import 'package:rsvp_rally/models/colors.dart';

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

      // Crop the image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop your profile picture',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            cropStyle: CropStyle.circle,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
            showCancelConfirmationDialog: true,
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        File croppedImageFile = File(croppedFile.path);
        List<int> imageBytes = await croppedImageFile.readAsBytes();
        print('Image size: ${imageBytes.length} bytes');

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

        pushProfilePicture(widget.username, base64Encode(imageBytes));

        setState(() {
          _profilePicBase64 = base64Encode(imageBytes);
        });
      }
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.only(top: 10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _changeProfilePicture,
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
              if (_profilePicBase64 != null)
                Positioned(
                  bottom: 5, // Adjusted for smaller CircleAvatar
                  right: -3, // Adjusted for smaller CircleAvatar
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
          ),
        ],
      ),
    );
  }
}
