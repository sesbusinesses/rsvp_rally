import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';

class PhaseEntryWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController locationController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final bool showEndTime;
  final VoidCallback onRemove;

  const PhaseEntryWidget({
    super.key,
    required this.nameController,
    required this.locationController,
    required this.startTimeController,
    required this.endTimeController,
    this.showEndTime = false,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WideTextBox(hintText: 'Phase Name', controller: nameController),
        WideTextBox(hintText: 'Phase Location', controller: locationController),
        WideTextBox(hintText: 'Start Time', controller: startTimeController),
        if (showEndTime)
          WideTextBox(hintText: 'End Time', controller: endTimeController),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
