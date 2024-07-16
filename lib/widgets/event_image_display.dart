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
        print('Image size: ${imageBytes.length} bytes');

        // Resize the image if it is too large
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
