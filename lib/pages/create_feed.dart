import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:rsvp_rally/widgets/widebutton.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class CreateFeedPage extends StatefulWidget {
  final String username;
  final double rating;

  const CreateFeedPage(
      {super.key, required this.username, required this.rating});

  @override
  CreateFeedPageState createState() => CreateFeedPageState();
}

class CreateFeedPageState extends State<CreateFeedPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String?> _base64Images = [null]; // List to hold images
  bool _isLoading = false;
  bool _isPosting = false;
  int _imageCount = 1; // Initial number of images

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      bool isGif = imageBytes
          .sublist(0, 3)
          .every((byte) => [0x47, 0x49, 0x46].contains(byte));

      CroppedFile? croppedFile;

      if (!isGif) {
        // Crop the image if it is not a GIF
        croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              aspectRatioPresets: [
                CropAspectRatioPreset.ratio16x9,
              ],
              cropStyle: CropStyle.rectangle,
            ),
            IOSUiSettings(
              title: 'Crop your image',
              aspectRatioPresets: [
                CropAspectRatioPreset.ratio16x9,
              ],
              cropStyle: CropStyle.rectangle,
              resetButtonHidden: true,
              aspectRatioPickerButtonHidden: true,
              showCancelConfirmationDialog: true,
            ),
            WebUiSettings(
              context: context,
            ),
          ],
        );
      } else {
        croppedFile = CroppedFile(file.path);
      }

      if (croppedFile != null) {
        File croppedImageFile = File(croppedFile.path);
        imageBytes = await croppedImageFile.readAsBytes();

        if (imageBytes.length > 100000) {
          img.Image? originalImage = img.decodeImage(imageBytes);
          if (originalImage != null) {
            if (isGif) {
              // Handle GIF
              img.GifDecoder gifDecoder = img.GifDecoder();
              img.Animation originalGif =
                  gifDecoder.decodeAnimation(imageBytes)!;
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
            } else {
              // Handle static images
              double reductionFactor = math.sqrt(100000 / imageBytes.length);
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

        setState(() {
          _base64Images[index] = base64Encode(imageBytes); // Store image in list
        });
      }
    }
  }

  Future<void> _postFeed() async {
    if (_isPosting) return; // Prevent multiple calls
    if (_base64Images.every((image) => image == null) ||
        _descriptionController.text.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please provide an image and description.',
                style: AppColors.bodyStyle),
            backgroundColor: AppColors.accentLight,
          ),
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isPosting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Feeds').add({
        'imageUrls': _base64Images.where((image) => image != null).toList(),
        'description': _descriptionController.text,
        'user': widget.username,
        'likes': [],
        'chat': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _notifyFriends();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post feed: $e'),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isPosting = false;
      });
    }
  }

  Future<void> _notifyFriends() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Timestamp timestamp = Timestamp.now();

    try {
      DocumentSnapshot userDoc =
          await firestore.collection('Users').doc(widget.username).get();
      if (!userDoc.exists) return;

      List<String> friends = List.from(userDoc['Friends'] ?? []);
      String messageText = '${widget.username} has posted';

      WriteBatch batch = firestore.batch();

      for (String friend in friends) {
        DocumentReference friendDocRef =
            firestore.collection('Users').doc(friend);
        batch.update(friendDocRef, {
          'Messages': FieldValue.arrayUnion([
            {'text': messageText, 'type': 'feed post', 'timestamp': timestamp}
          ]),
          'NewMessages': true,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying friends: $e');
    }
  }

  void _onPostButtonPressed() {
    if (!_isLoading) {
      _postFeed();
    }
  }

  void _incrementImageCount() {
    setState(() {
      if (_imageCount < 3) {
        _imageCount++;
        _base64Images.add(null); // Add new image slot
      }
    });
  }

  void _decrementImageCount() {
    setState(() {
      if (_imageCount > 1) {
        _imageCount--;
        _base64Images.removeLast(); // Remove last image slot
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = getInterpolatedColor(widget.rating);
    Color buttonColor = getInterpolatedColor(widget.rating);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        color: _imageCount > 1 ? buttonColor : Colors.grey,
                      ),
                      onPressed: _imageCount > 1 ? _decrementImageCount : null,
                    ),
                    Text(
                      '$_imageCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: _imageCount < 3 ? buttonColor : Colors.grey,
                      ),
                      onPressed: _imageCount < 3 ? _incrementImageCount : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(_imageCount, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: GestureDetector(
                      onTap: () => _pickImage(index),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: borderColor,
                            width: AppColors.borderWidth,
                          ),
                        ),
                        child: _base64Images[index] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(
                                  base64Decode(_base64Images[index]!),
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
                  );
                }),
                const SizedBox(height: 10),
                WideTextBox(
                  hintText: 'Caption',
                  controller: _descriptionController,
                  canGrow: true,
                ),
                const SizedBox(height: 10),
                WideButton(
                  buttonText: 'Post',
                  onPressed: _onPostButtonPressed, // Disable button if loading
                  rating: widget.rating,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
