import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class SharedAlbumPage extends StatefulWidget {
  final String eventID;
  final String username;
  final double rating;

  const SharedAlbumPage({
    super.key,
    required this.eventID,
    required this.username,
    required this.rating,
  });

  @override
  _SharedAlbumPageState createState() => _SharedAlbumPageState();
}

class _SharedAlbumPageState extends State<SharedAlbumPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        List<int> imageBytes = await file.readAsBytes();

        // Resize the image if it is too large
        if (imageBytes.length > 1000000) {
          img.Image? originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            double reductionFactor = math.sqrt(1000000 / imageBytes.length);
            int newWidth = (originalImage.width * reductionFactor).toInt();
            int newHeight = (originalImage.height * reductionFactor).toInt();

            img.Image resizedImage = img.copyResize(originalImage,
                width: newWidth, height: newHeight);

            // Adjust the quality parameter to reduce file size
            imageBytes = img.encodeJpg(resizedImage, quality: 75);
          }
        }

        String base64Image = base64Encode(imageBytes);

        // Create a new photo document in the sub-collection
        final photoRef = FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventID)
            .collection('Photos')
            .doc();
        final photo = Photo(
          id: photoRef.id,
          base64Image: base64Image,
          uploadedBy: widget.username,
          likedBy: [],
          downloadedBy: [],
        );
        await photoRef.set(photo.toMap());
      }
    } catch (e) {
      print('Error picking or uploading photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Album', style: AppColors.topStyle),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventID)
            .collection('Photos')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final photos = snapshot.data!.docs.map((doc) {
            return Photo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Image.memory(base64Decode(photo.base64Image));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadPhoto,
        backgroundColor: getInterpolatedColor(widget.rating),
        child:
            Icon(Icons.add_a_photo, color: getTextOnRatingColor(widget.rating)),
      ),
    );
  }
}

class Photo {
  String id;
  String base64Image;
  String uploadedBy;
  List<String> likedBy;
  List<String> downloadedBy;

  Photo({
    required this.id,
    required this.base64Image,
    required this.uploadedBy,
    required this.likedBy,
    required this.downloadedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'base64Image': base64Image,
      'uploadedBy': uploadedBy,
      'likedBy': likedBy,
      'downloadedBy': downloadedBy,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map, String id) {
    return Photo(
      id: id,
      base64Image: map['base64Image'],
      uploadedBy: map['uploadedBy'],
      likedBy: List<String>.from(map['likedBy']),
      downloadedBy: List<String>.from(map['downloadedBy']),
    );
  }
}
