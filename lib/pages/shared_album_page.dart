import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

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
  final Set<String> _selectedPhotos = {};
  late List<Photo> _photos;
  bool _selectMode = false;

  Future<void> _pickAndUploadPhoto() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (XFile image in images) {
          File file = File(image.path);
          List<int> imageBytes = await file.readAsBytes();

          // Check if the image is a GIF
          if (imageBytes.sublist(0, 6).every((byte) => [
                0x47,
                0x49,
                0x46,
                0x38,
                0x39,
                0x61,
                0x38,
                0x37,
                0x61
              ].contains(byte))) {
            // Handle GIF
            img.GifDecoder gifDecoder = img.GifDecoder();
            img.Animation? originalGif = gifDecoder.decodeAnimation(imageBytes);
            if (originalGif != null && imageBytes.length > 100000) {
              img.Animation resizedGif = img.Animation();

              double reductionFactor = math.sqrt(100000 / imageBytes.length);
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
            }
          } else {
            // Handle static images
            if (imageBytes.length > 100000) {
              img.Image? originalImage = img.decodeImage(imageBytes);
              if (originalImage != null) {
                double reductionFactor = math.sqrt(100000 / imageBytes.length);
                int newWidth = (originalImage.width * reductionFactor).toInt();
                int newHeight =
                    (originalImage.height * reductionFactor).toInt();

                img.Image resizedImage = img.copyResize(originalImage,
                    width: newWidth, height: newHeight);

                // Adjust the quality parameter to reduce file size
                imageBytes = img.encodeJpg(resizedImage, quality: 75);
              }
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
      }
    } catch (e) {
      print('Error picking or uploading photos: $e');
    }
  }

  void _viewPhoto(Photo photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(base64Decode(photo.base64Image)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Uploaded by ${photo.uploadedBy}'),
            ),
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                color: photo.likedBy.contains(widget.username)
                    ? Colors.blue
                    : Colors.grey,
              ),
              onPressed: () async {
                if (!photo.likedBy.contains(widget.username)) {
                  photo.likedBy.add(widget.username);
                  await FirebaseFirestore.instance
                      .collection('Events')
                      .doc(widget.eventID)
                      .collection('Photos')
                      .doc(photo.id)
                      .update({'likedBy': photo.likedBy});
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadSelectedPhotos() async {
    for (String photoId in _selectedPhotos) {
      DocumentSnapshot photoDoc = await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .collection('Photos')
          .doc(photoId)
          .get();

      if (photoDoc.exists) {
        Photo photo =
            Photo.fromMap(photoDoc.data() as Map<String, dynamic>, photoDoc.id);
        Uint8List imageBytes = base64Decode(photo.base64Image);
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 60,
          name: photo.id,
        );
        print(result);

        if (!photo.downloadedBy.contains(widget.username)) {
          photo.downloadedBy.add(widget.username);
          await FirebaseFirestore.instance
              .collection('Events')
              .doc(widget.eventID)
              .collection('Photos')
              .doc(photo.id)
              .update({'downloadedBy': photo.downloadedBy});
        }
      }
    }

    setState(() {
      _selectedPhotos.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected photos downloaded')),
    );
  }

  void _deleteSelectedPhotos() async {
    for (String photoId in _selectedPhotos) {
      DocumentSnapshot photoDoc = await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .collection('Photos')
          .doc(photoId)
          .get();

      if (photoDoc.exists) {
        Photo photo =
            Photo.fromMap(photoDoc.data() as Map<String, dynamic>, photoDoc.id);
        if (photo.uploadedBy == widget.username) {
          await FirebaseFirestore.instance
              .collection('Events')
              .doc(widget.eventID)
              .collection('Photos')
              .doc(photoId)
              .delete();
        }
      }
    }

    setState(() {
      _selectedPhotos.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected photos deleted')),
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selectedPhotos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Album', style: AppColors.topStyle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_selectMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectMode,
          ),
          if (_selectMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _selectedPhotos.clear();
                  _selectedPhotos.addAll(_photos.map((photo) => photo.id));
                });
              },
            ),
          if (_selectMode)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed:
                  _selectedPhotos.isEmpty ? null : _downloadSelectedPhotos,
            ),
          if (_selectMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedPhotos.isEmpty ? null : _deleteSelectedPhotos,
            ),
        ],
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

          _photos = snapshot.data!.docs.map((doc) {
            return Photo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final isSelected = _selectedPhotos.contains(photo.id);
              return GestureDetector(
                onTap: _selectMode
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedPhotos.remove(photo.id);
                          } else {
                            _selectedPhotos.add(photo.id);
                          }
                        });
                      }
                    : () => _viewPhoto(photo),
                child: Stack(
                  children: [
                    Center(
                        child: Image.memory(base64Decode(photo.base64Image))),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.check_circle,
                            color: getInterpolatedColor(widget.rating)),
                      ),
                  ],
                ),
              );
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
