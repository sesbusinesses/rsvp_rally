import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/phase_entry_widget.dart';

class PhasesSection extends StatelessWidget {
  final List<Map<String, TextEditingController>> phaseControllers;
  final VoidCallback onAddPhase;
  final Function(int) onRemovePhase;

  const PhasesSection({
    super.key,
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
          border: Border.all(color: AppColors.dark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('Add Phases', style: TextStyle(fontSize: 20)),
            TextButton(onPressed: onAddPhase, child: const Text('Add Phase')),
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
