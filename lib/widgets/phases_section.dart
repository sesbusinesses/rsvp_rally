import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/phase_entry_widget.dart';

class PhasesSection extends StatelessWidget {
  final double rating;
  final List<Map<String, TextEditingController>> phaseControllers;
  final VoidCallback onAddPhase;
  final Function(int) onRemovePhase;

  const PhasesSection({
    super.key,
    required this.rating,
    required this.phaseControllers,
    required this.onAddPhase,
    required this.onRemovePhase,
  });

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: screenSize.width * 0.85,
        decoration: BoxDecoration(
          border: Border.all(color: getInterpolatedColor(rating)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('Add Phases',
                style: TextStyle(
                  fontSize: 20,
                )),
            ElevatedButton(
              onPressed: onAddPhase,
              style: ElevatedButton.styleFrom(
                backgroundColor: getInterpolatedColor(rating),
              ),
              child: const Text('Add Phase',
                  style: TextStyle(color: AppColors.dark)),
            ),
            ...List.generate(phaseControllers.length, (index) {
              return PhaseEntryWidget(
                nameController: phaseControllers[index]['name']!,
                locationController: phaseControllers[index]['location']!,
                startTimeController: phaseControllers[index]['startTime']!,
                endTimeController: phaseControllers[index]['endTime']!,
                showEndTime: index == phaseControllers.length - 1,
                onRemove: () => onRemovePhase(index),
              );
            }),
          ],
        ));
  }
}
