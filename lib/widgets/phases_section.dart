import 'package:flutter/material.dart';
import 'package:rsvp_rally/config/config.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/bracket_painter.dart';
import 'package:rsvp_rally/widgets/places_autocomplete.dart';
import 'package:rsvp_rally/widgets/widetextbox.dart';
import 'package:rsvp_rally/widgets/time_picker.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

class PhasesSection extends StatefulWidget {
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
  _PhasesSectionState createState() => _PhasesSectionState();
}

class _PhasesSectionState extends State<PhasesSection> {
  Future<void> _selectDateTime(BuildContext context,
      TextEditingController controller, double rating) async {
    DateTime? dateTime = await selectDateTime(context, rating);
    if (dateTime != null) {
      controller.text = DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 10, horizontal: screenSize.width * 0.05),
      width: screenSize.width * 0.95,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: getInterpolatedColor(widget.rating),
          width: AppColors.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Add Phases',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          ElevatedButton(
            onPressed: widget.onAddPhase,
            style: ElevatedButton.styleFrom(
              backgroundColor: getInterpolatedColor(widget.rating),
            ),
            child: const Text(
              'Add Phase',
              style: TextStyle(color: AppColors.dark),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(widget.phaseControllers.length * 2 + 1, (index) {
            final int phaseIndex = index ~/ 2;
            final bool isStartNode = index % 2 == 0;
            final bool isEndNode = index == widget.phaseControllers.length * 2;

            if (isStartNode && phaseIndex < widget.phaseControllers.length) {
              return buildTimelineTile(
                begins: phaseIndex == 0,
                isStartNode: true,
                isEndNode: false,
                phaseData: widget.phaseControllers[phaseIndex],
                onRemove: () => widget.onRemovePhase(phaseIndex),
                rating: widget.rating,
                selectDateTime: _selectDateTime,
              );
            } else if (isEndNode && widget.phaseControllers.isNotEmpty) {
              return buildTimelineTile(
                isStartNode: false,
                isEndNode: true,
                phaseData: widget.phaseControllers.last,
                onRemove: () => widget.onRemovePhase(phaseIndex - 1),
                rating: widget.rating,
                selectDateTime: _selectDateTime,
              );
            } else if (!isStartNode &&
                phaseIndex < widget.phaseControllers.length) {
              return buildTimelineTile(
                isStartNode: false,
                isEndNode: false,
                phaseData: widget.phaseControllers[phaseIndex],
                onRemove: () => widget.onRemovePhase(phaseIndex),
                rating: widget.rating,
                selectDateTime: _selectDateTime,
              );
            } else {
              return Container(); // Return an empty container if indices are out of range
            }
          }),
        ],
      ),
    );
  }

  Widget buildTimelineTile({
    begins = false,
    required bool isStartNode,
    required bool isEndNode,
    required Map<String, TextEditingController> phaseData,
    required VoidCallback onRemove,
    required double rating,
    required Function(BuildContext, TextEditingController, double)
        selectDateTime,
  }) {
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.15,
      isFirst: begins,
      isLast: isEndNode,
      indicatorStyle: IndicatorStyle(
        width: 30,
        color: isStartNode || isEndNode
            ? Colors.transparent
            : getInterpolatedColor(rating),
        iconStyle: IconStyle(
          color: getInterpolatedColor(rating),
          iconData: isStartNode || isEndNode
              ? Icons.access_time
              : Icons.fiber_manual_record,
        ),
      ),
      beforeLineStyle: LineStyle(
        color: getInterpolatedColor(rating),
        thickness: 4,
      ),
      startChild: (!isStartNode && !isEndNode)
          ? GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.remove_circle),
            )
          : Container(),
      endChild: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.only(left: 10),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (!isStartNode && !isEndNode)
              CustomPaint(
                size: const Size(20, 100),
                painter: BracketPainter(getInterpolatedColor(rating)),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isStartNode || isEndNode)
                    InkWell(
                      onTap: () => selectDateTime(
                        context,
                        isStartNode
                            ? phaseData['startTime']!
                            : phaseData['endTime']!,
                        rating,
                      ),
                      child: IgnorePointer(
                        child: WideTextBox(
                          hintText: isStartNode ? 'Start Time' : 'End Time',
                          controller: isStartNode
                              ? phaseData['startTime']!
                              : phaseData['endTime']!,
                        ),
                      ),
                    ),
                  if (isStartNode || isEndNode)
                    const SizedBox(
                      height: 5,
                    ),
                  if (!isStartNode && !isEndNode)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WideTextBox(
                          hintText: 'Phase Name',
                          controller: phaseData['name']!,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        PlacesAutocomplete(
                          apiKey: Config
                              .googleMapsApiKey, // Use the actual API key here
                          onPlaceSelected: (placeId, description) {
                            phaseData['location']!.text = description;
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        )
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
