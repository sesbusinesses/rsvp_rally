import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'dart:math' as math;

import 'package:rsvp_rally/widgets/widetextbox.dart';

class CreateFeedPage extends StatefulWidget {
  final String username;
  final double rating;

  const CreateFeedPage(
      {super.key, required this.username, required this.rating});

  @override
  _CreateFeedPageState createState() => _CreateFeedPageState();
}

class _CreateFeedPageState extends State<CreateFeedPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      if (imageBytes.length > 1000000) {
        img.Image? originalImage = img.decodeImage(imageBytes);
        if (originalImage != null) {
          if (imageBytes.sublist(0, 6).every(
              (byte) => [0x47, 0x49, 0x46, 0x38, 0x39, 0x61].contains(byte))) {
            // Handle GIF
            img.GifDecoder gifDecoder = img.GifDecoder();
            img.Animation originalGif = gifDecoder.decodeAnimation(imageBytes)!;
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
            int jpegQuality = 75; // You can adjust this value between 0 and 100
            imageBytes = img.encodeJpg(resizedImage, quality: jpegQuality);
          }
          print('Resized image size: ${imageBytes.length} bytes');
        }
      }

      setState(() {
        _base64Image = base64Encode(imageBytes);
      });
    }
  }

  Future<void> _postFeed() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide an image and description.',
              style: AppColors.bodyStyle),
          backgroundColor: AppColors.accentLight,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Feeds').add({
        'imageUrl': _base64Image,
        'description': _descriptionController.text,
        'user': widget.username,
        'likes': [],
        'chat': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post feed: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = getInterpolatedColor(widget.rating);
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Feed', style: AppColors.topStyle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: getInterpolatedColor(widget.rating),
                          width: AppColors.borderWidth),
                    ),
                    child: _base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              base64Decode(_base64Image!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.add_a_photo,
                              color: borderColor,
                              size: 50,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                WideTextBox(
                  hintText: 'Caption',
                  controller: _descriptionController,
                  canGrow: true,
                ),
                // TextField(
                //   controller: _descriptionController,
                //   maxLines: 2,
                //   decoration: InputDecoration(
                //     hintText: 'Enter description',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(15),
                //       borderSide: BorderSide(color: borderColor),
                //     ),
                //     focusedBorder: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(15),
                //       borderSide: BorderSide(color: borderColor),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 10),
                WideButton(
                  buttonText: 'Post',
                  onPressed: _postFeed,
                  rating: widget.rating,
                ),
                // Center(
                //   child: _isLoading
                //       ? const CircularProgressIndicator()
                //       : ElevatedButton(
                //           onPressed: _postFeed,
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor:
                //                 getInterpolatedColor(widget.rating),
                //             padding: const EdgeInsets.symmetric(
                //                 horizontal: 50, vertical: 15),
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(30),
                //             ),
                //           ),
                //           child: Text(
                //             'Post',
                //             style: AppColors.buttonStyle,
                //           ),
                //         ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
