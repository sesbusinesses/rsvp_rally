import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/time_picker.dart';
import 'package:rsvp_rally/widgets/places_autocomplete.dart';
import 'package:rsvp_rally/config/config.dart';

class PhaseEntryWidget extends StatelessWidget {
  final double rating;
  final TextEditingController nameController;
  final TextEditingController locationController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final bool showEndTime;
  final VoidCallback onRemove;

  const PhaseEntryWidget({
    super.key,
    required this.rating,
    required this.nameController,
    required this.locationController,
    required this.startTimeController,
    required this.endTimeController,
    this.showEndTime = false,
    required this.onRemove,
  });

  Future<void> _selectStartTime(BuildContext context) async {
    DateTime? dateTime = await selectDateTime(context, rating);
    if (dateTime != null) {
      startTimeController.text = dateTime.toIso8601String();
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    DateTime? dateTime = await selectDateTime(context, rating);
    if (dateTime != null) {
      endTimeController.text = dateTime.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WideTextBox(hintText: 'Phase Name', controller: nameController),
        PlacesAutocomplete(
          apiKey: Config.googleMapsApiKey, // Use the actual API key here
          onPlaceSelected: (placeId, description) {
            locationController.text = description;
          },
        ),
        InkWell(
          onTap: () => _selectStartTime(context),
          child: IgnorePointer(
            child: WideTextBox(
              hintText: 'Start Time',
              controller: startTimeController,
            ),
          ),
        ),
        if (showEndTime)
          InkWell(
            onTap: () => _selectEndTime(context),
            child: IgnorePointer(
              child: WideTextBox(
                hintText: 'End Time',
                controller: endTimeController,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
