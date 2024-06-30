import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class EventImageDisplay extends StatefulWidget {
  final String eventID;
  final double rating;

  const EventImageDisplay({
    super.key,
    required this.eventID,
    required this.rating,
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
        String base64Image = base64Encode(await file.readAsBytes());
        setState(() {
          _imageBase64 = base64Image;
        });
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
    return GestureDetector(
      onTap: _pickImage,
      child: _imageBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(_imageBase64!),
                fit: BoxFit.cover,
              ),
            )
          : const Expanded(
              child: FittedBox(
                child: Icon(
                  Icons.add_a_photo,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }
}
