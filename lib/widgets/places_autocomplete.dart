import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class PlacesAutocomplete extends StatefulWidget {
  final String apiKey;
  final Function(String placeId, String description) onPlaceSelected;

  const PlacesAutocomplete({
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  _PlacesAutocompleteState createState() => _PlacesAutocompleteState();
}

class _PlacesAutocompleteState extends State<PlacesAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  List<Prediction> _predictions = [];
  late GoogleMapsPlaces _places;

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    final response = await _places.autocomplete(input);
    if (response.isOkay) {
      setState(() {
        _predictions = response.predictions;
      });
    } else {
      print("Places API Error: ${response.errorMessage}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _searchPlaces,
          decoration: InputDecoration(
            labelText: "Event Location",
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        if (_predictions.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.description ?? ''),
                  onTap: () async {
                    final detail = await _places.getDetailsByPlaceId(prediction.placeId!);
                    widget.onPlaceSelected(prediction.placeId!, detail.result.formattedAddress ?? '');
                    setState(() {
                      _controller.text = detail.result.formattedAddress ?? '';
                      _predictions = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
