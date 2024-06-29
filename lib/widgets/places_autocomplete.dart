import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlacesAutocomplete extends StatefulWidget {
  final String apiKey;
  final Function(String placeId, String description) onPlaceSelected;
  final String? eventID; // Make eventID optional
  final int? phaseIndex; // Make phaseIndex optional
  final TextEditingController controller;

  const PlacesAutocomplete({
    required this.apiKey,
    required this.onPlaceSelected,
    this.eventID, // Make eventID optional
    this.phaseIndex, // Make phaseIndex optional,
    required this.controller,
    super.key,
  });

  @override
  _PlacesAutocompleteState createState() => _PlacesAutocompleteState();
}

class _PlacesAutocompleteState extends State<PlacesAutocomplete> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places;
  final FocusNode _focusNode = FocusNode();
  String _hintText = "Event Location"; // Default placeholder

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
    _loadHintText();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      _hideOverlay();
      return;
    }

    final response = await _places.autocomplete(input);
    if (response.isOkay) {
      setState(() {
        _predictions = response.predictions;
      });
      _showOverlay();
    } else {
      print("Places API Error: ${response.errorMessage}");
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    title: Text(prediction.description ?? ''),
                    onTap: () async {
                      final detail = await _places
                          .getDetailsByPlaceId(prediction.placeId!);
                      widget.onPlaceSelected(prediction.placeId!,
                          detail.result.formattedAddress ?? '');
                      widget.controller.text = detail.result.formattedAddress ?? '';
                      _hideOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadHintText() async {
    if (widget.eventID != null && widget.phaseIndex != null) {
      try {
        DocumentSnapshot eventDoc = await FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventID)
            .get();
        if (eventDoc.exists) {
          Map<String, dynamic> eventData =
              eventDoc.data() as Map<String, dynamic>;
          List<dynamic> phases = eventData['phases'] ?? [];
          if (widget.phaseIndex! < phases.length) {
            String location = phases[widget.phaseIndex!]['location'] ?? '';
            setState(() {
              _hintText = location.isNotEmpty ? location : _hintText;
            });
          }
        }
      } catch (e) {
        print('Error fetching phase location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 5, top: 10, bottom: 10),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: _searchPlaces,
            decoration: InputDecoration(
              hintText: _hintText,
              prefixIcon: const Icon(Icons.location_on),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
