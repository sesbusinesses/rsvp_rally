import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/time_picker.dart';

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

  Future<void> _selectStartTime(BuildContext context) async {
    DateTime? dateTime = await selectDateTime(context);
    if (dateTime != null) {
      startTimeController.text = dateTime.toIso8601String();
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    DateTime? dateTime = await selectDateTime(context);
    if (dateTime != null) {
      endTimeController.text = dateTime.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WideTextBox(hintText: 'Phase Name', controller: nameController),
        WideTextBox(hintText: 'Phase Location', controller: locationController),
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
