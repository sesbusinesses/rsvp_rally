import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';

class CreateFeedPage extends StatefulWidget {
  final String username;

  const CreateFeedPage({required this.username, Key? key}) : super(key: key);

  @override
  _CreateFeedPageState createState() => _CreateFeedPageState();
}

class _CreateFeedPageState extends State<CreateFeedPage> {
  final ImagePicker _picker = ImagePicker();
  String? _imageBase64;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        List<int> imageBytes = await file.readAsBytes();

        // Resize the image if it is too large
        if (imageBytes.length > 15000) {
          img.Image? originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            double reductionFactor = math.sqrt(15000 / imageBytes.length);
            img.Image resizedImage = img.copyResize(originalImage,
                width: (originalImage.width * reductionFactor).toInt());
            imageBytes = img.encodeJpg(resizedImage);
          }
        }

        setState(() {
          _imageBase64 = base64Encode(imageBytes);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _createPost() async {
    if (_imageBase64 != null && _descriptionController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('Feeds').add({
          'imageUrl': _imageBase64,
          'description': _descriptionController.text,
          'user': widget.username,
          'likes': [],
          'chat': [],
          'timestamp': FieldValue.serverTimestamp(), // Add timestamp field
        });
        Navigator.pop(context);
      } catch (e) {
        print('Error creating post: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image and enter a description.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          base64Decode(_imageBase64!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Icon(Icons.add_a_photo, color: Colors.grey[800], size: 50),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Enter description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createPost,
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
