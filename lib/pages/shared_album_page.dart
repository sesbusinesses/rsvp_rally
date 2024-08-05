import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Add this import
import 'dart:async';

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
  bool _isAllowedAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.eventID)
          .get();
      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        Map<String, String> attendees =
            Map<String, String>.from(eventData['Attendees']);
        setState(() {
          _isAllowedAccess = attendees[widget.username] == 'yes';
        });
      }
    } catch (e) {
      print('Error checking access: $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (XFile image in images) {
          File file = File(image.path);
          List<int> imageBytes = await file.readAsBytes();

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
            if (imageBytes.length > 100000) {
              img.Image? originalImage = img.decodeImage(imageBytes);
              if (originalImage != null) {
                double reductionFactor = math.sqrt(100000 / imageBytes.length);
                int newWidth = (originalImage.width * reductionFactor).toInt();
                int newHeight =
                    (originalImage.height * reductionFactor).toInt();

                img.Image resizedImage = img.copyResize(originalImage,
                    width: newWidth, height: newHeight);

                imageBytes = img.encodeJpg(resizedImage, quality: 75);
              }
            }
          }

          String base64Image = base64Encode(imageBytes);

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
            dislikedBy: [],
            downloadedBy: [],
          );
          await photoRef.set(photo.toMap());
        }
      }
    } catch (e) {
      print('Error picking or uploading photos: $e');
    }
  }

  void _viewPhoto(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                    maxHeight: MediaQuery.of(context).size.height),
                child: ExpandablePageView(
                  initialPage: index,
                  children: _photos.map((photo) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.memory(base64Decode(photo.base64Image)),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: getInterpolatedColor(widget.rating),
                                    width: AppColors.borderWidth),
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.light,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child:
                                        Text('Uploaded by ${photo.uploadedBy}'),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.thumb_up,
                                              color: photo.likedBy
                                                      .contains(widget.username)
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              if (photo.likedBy
                                                  .contains(widget.username)) {
                                                photo.likedBy
                                                    .remove(widget.username);
                                              } else {
                                                photo.likedBy
                                                    .add(widget.username);
                                                photo.dislikedBy
                                                    .remove(widget.username);
                                              }
                                              await FirebaseFirestore.instance
                                                  .collection('Events')
                                                  .doc(widget.eventID)
                                                  .collection('Photos')
                                                  .doc(photo.id)
                                                  .update({
                                                'likedBy': photo.likedBy,
                                                'dislikedBy': photo.dislikedBy,
                                              });
                                              setState(() {});
                                            },
                                          ),
                                          FutureBuilder<List<String?>>(
                                            future: Future.wait(photo.likedBy
                                                .map((username) =>
                                                    _fetchProfilePicture(
                                                        username))
                                                .toList()),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                      ConnectionState.done &&
                                                  snapshot.hasData) {
                                                return Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: snapshot.data!.map(
                                                      (profilePictureData) {
                                                    return CircleAvatar(
                                                      radius: 15,
                                                      backgroundImage:
                                                          profilePictureData !=
                                                                  null
                                                              ? MemoryImage(
                                                                  base64Decode(
                                                                      profilePictureData))
                                                              : null,
                                                      child:
                                                          profilePictureData ==
                                                                  null
                                                              ? const Icon(
                                                                  Icons.person,
                                                                  size: 20,
                                                                  color: Colors
                                                                      .grey)
                                                              : null,
                                                    );
                                                  }).toList(),
                                                );
                                              } else {
                                                return Container();
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.thumb_down,
                                              color: photo.dislikedBy
                                                      .contains(widget.username)
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              if (photo.dislikedBy
                                                  .contains(widget.username)) {
                                                photo.dislikedBy
                                                    .remove(widget.username);
                                              } else {
                                                photo.dislikedBy
                                                    .add(widget.username);
                                                photo.likedBy
                                                    .remove(widget.username);
                                              }
                                              await FirebaseFirestore.instance
                                                  .collection('Events')
                                                  .doc(widget.eventID)
                                                  .collection('Photos')
                                                  .doc(photo.id)
                                                  .update({
                                                'likedBy': photo.likedBy,
                                                'dislikedBy': photo.dislikedBy,
                                              });
                                              setState(() {});
                                            },
                                          ),
                                          FutureBuilder<List<String?>>(
                                            future: Future.wait(photo.dislikedBy
                                                .map((username) =>
                                                    _fetchProfilePicture(
                                                        username))
                                                .toList()),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                      ConnectionState.done &&
                                                  snapshot.hasData) {
                                                return Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 4.0,
                                                  children: snapshot.data!.map(
                                                      (profilePictureData) {
                                                    return CircleAvatar(
                                                      radius: 15,
                                                      backgroundImage:
                                                          profilePictureData !=
                                                                  null
                                                              ? MemoryImage(
                                                                  base64Decode(
                                                                      profilePictureData))
                                                              : null,
                                                      child:
                                                          profilePictureData ==
                                                                  null
                                                              ? const Icon(
                                                                  Icons.person,
                                                                  size: 20,
                                                                  color: Colors
                                                                      .grey)
                                                              : null,
                                                    );
                                                  }).toList(),
                                                );
                                              } else {
                                                return Container();
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              )),
        );
      },
    );
  }

  Future<String?> _fetchProfilePicture(String username) async {
    return await pullProfilePicture(username);
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

  Future<void> _deleteSelectedPhotos() async {
    final userUploadedPhotos = _selectedPhotos.where((photoId) {
      final photo = _photos.firstWhere((photo) => photo.id == photoId);
      return photo.uploadedBy == widget.username;
    }).toList();

    if (userUploadedPhotos.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text(
            'Are you sure you want to delete the ${userUploadedPhotos.length} photos that you uploaded? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      for (String photoId in userUploadedPhotos) {
        await FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventID)
            .collection('Photos')
            .doc(photoId)
            .delete();
      }

      setState(() {
        _selectedPhotos.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected photos deleted')),
      );
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selectedPhotos.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPhotos.length == _photos.length) {
        _selectedPhotos.clear();
      } else {
        _selectedPhotos.addAll(_photos.map((photo) => photo.id));
      }
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
              onPressed: _toggleSelectAll,
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
      body: _isAllowedAccess
          ? StreamBuilder<QuerySnapshot>(
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
                  return Photo.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
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
                          : () => _viewPhoto(index),
                      child: Stack(
                        children: [
                          Center(
                              child: Image.memory(
                                  base64Decode(photo.base64Image))),
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
            )
          : Center(
              child: Text(
                'RSVP \'Yes\' to access the album',
                style: AppColors.bodyStyle,
              ),
            ),
      floatingActionButton: _isAllowedAccess
          ? FloatingActionButton(
              onPressed: _pickAndUploadPhoto,
              backgroundColor: getInterpolatedColor(widget.rating),
              child: Icon(Icons.add_a_photo,
                  color: getTextOnRatingColor(widget.rating)),
            )
          : null,
    );
  }
}

class Photo {
  String id;
  String base64Image;
  String uploadedBy;
  List<String> likedBy;
  List<String> dislikedBy;
  List<String> downloadedBy;

  Photo({
    required this.id,
    required this.base64Image,
    required this.uploadedBy,
    required this.likedBy,
    required this.dislikedBy,
    required this.downloadedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'base64Image': base64Image,
      'uploadedBy': uploadedBy,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'downloadedBy': downloadedBy,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map, String id) {
    return Photo(
      id: id,
      base64Image: map['base64Image'],
      uploadedBy: map['uploadedBy'],
      likedBy: List<String>.from(map['likedBy']),
      dislikedBy: List<String>.from(map['dislikedBy']),
      downloadedBy: List<String>.from(map['downloadedBy']),
    );
  }
}

class ExpandablePageView extends StatefulWidget {
  final List<Widget> children;
  final int initialPage;

  const ExpandablePageView({
    super.key,
    required this.children,
    this.initialPage = 0,
  });

  @override
  State<ExpandablePageView> createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late List<double> _heights;
  int _currentPage = 0;

  double get _currentHeight => _heights[_currentPage];

  @override
  void initState() {
    super.initState();
    _heights = widget.children.map((e) => 0.0).toList();
    _pageController = PageController(initialPage: widget.initialPage)
      ..addListener(() {
        final newPage = _pageController.page?.round() ?? 0;
        if (_currentPage != newPage) {
          setState(() {
            _currentPage = newPage;
          });
        }
      });
    _currentPage = widget.initialPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_heights[_currentPage] == 0.0 && mounted) {
        setState(() {
          _heights[_currentPage] = context.size!.height;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ExpandablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      _pageController.jumpToPage(widget.initialPage);
      setState(() {
        _currentPage = widget.initialPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 100),
      tween: Tween<double>(begin: _heights[_currentPage], end: _currentHeight),
      builder: (context, value, child) {
        return SizedBox(height: value, child: child);
      },
      child: PageView(
        controller: _pageController,
        children: _sizeReportingChildren
            .asMap()
            .map((index, child) => MapEntry(index, child))
            .values
            .toList(),
      ),
    );
  }

  List<Widget> get _sizeReportingChildren => widget.children
      .asMap()
      .map(
        (index, child) => MapEntry(
          index,
          OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: SizeReportingWidget(
              onSizeChange: (size) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _heights[index] = size.height;
                  });
                });
              },
              child: Align(child: child),
            ),
          ),
        ),
      )
      .values
      .toList();
}

class SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChange;

  const SizeReportingWidget({
    super.key,
    required this.child,
    required this.onSizeChange,
  });

  @override
  State<SizeReportingWidget> createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<SizeReportingWidget> {
  Size? _oldSize;
  Timer? _debounceTimer;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    return widget.child;
  }

  void _notifySize() {
    if (!mounted) return;
    final size = context.size;
    if (_oldSize != size && size != null) {
      _oldSize = size;

      // Debounce size change notifications
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 40), () {
        widget.onSizeChange(size);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
