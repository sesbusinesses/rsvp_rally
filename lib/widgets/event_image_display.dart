import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

class EventImageDisplay extends StatefulWidget {
  final String eventID;
  final double rating;
  final bool clickable;

  const EventImageDisplay({
    super.key,
    required this.eventID,
    required this.rating,
    required this.clickable,
  });

  @override
  _EventImageDisplayState createState() => _EventImageDisplayState();
}

class _EventImageDisplayState extends State<EventImageDisplay> {
  final ImagePicker _picker = ImagePicker();
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .get();
      if (eventSnapshot.exists) {
        String? base64Image = eventSnapshot['Image'];
        setState(() {
          _imageBase64 = base64Image;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        List<int> imageBytes = await file.readAsBytes();

        // Resize the image if it is too large
        if (imageBytes.length > 1000000) {
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
        setState(() {
          _imageBase64 = base64Image;
        });
        print(base64Image);
        print(base64Image.length);
        await FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventID)
            .update({'Image': base64Image});
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.clickable
        ? GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: _imageBase64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(_imageBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        color: Colors.grey,
                      ),
                    ),
            ),
          )
        : Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: _imageBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      color: Colors.grey,
                    ),
                  ),
          );
  }
}
