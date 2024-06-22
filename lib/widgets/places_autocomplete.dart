import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:rsvp_rally/models/colors.dart';

class PlacesAutocomplete extends StatefulWidget {
  final String apiKey;
  final Function(String placeId, String description) onPlaceSelected;

  const PlacesAutocomplete({
    required this.apiKey,
    required this.onPlaceSelected,
    Key? key,
  }) : super(key: key);

  @override
  _PlacesAutocompleteState createState() => _PlacesAutocompleteState();
}

class _PlacesAutocompleteState extends State<PlacesAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places;
  FocusNode _focusNode = FocusNode();

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
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
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
    Overlay.of(context)?.insert(_overlayEntry!);
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
                color: AppColors.accent,
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
                      final detail = await _places.getDetailsByPlaceId(prediction.placeId!);
                      widget.onPlaceSelected(prediction.placeId!, detail.result.formattedAddress ?? '');
                      _controller.text = detail.result.formattedAddress ?? '';
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 5, top: 10, bottom: 5),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _searchPlaces,
            decoration: InputDecoration(
              hintText: "Event Location",
              prefixIcon: Icon(Icons.location_on),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
