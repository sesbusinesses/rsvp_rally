import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Ensure this path is correct
import 'package:intl/intl.dart';
// Firestore timestamp handling

class EventTimeline extends StatelessWidget {
  final double rating;
  final String eventID;

  const EventTimeline({super.key, required this.eventID, required this.rating});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTimeline(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var timelineData = snapshot.data!;
            // Adjust the count to handle each phase being split into two nodes, plus one for the last end time
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final int phaseIndex = index ~/ 2;
                  final bool isStartNode = index % 2 == 0;
                  if (phaseIndex < timelineData.length) {
                    final data = timelineData[phaseIndex];
                    return buildTimelineTile(data, phaseIndex,
                        timelineData.length, isStartNode, false);
                  } else {
                    // Handling the extra node for displaying the end time of the last phase
                    final lastData = timelineData.last;
                    return buildTimelineTile(
                        lastData, phaseIndex, timelineData.length, false, true);
                  }
                },
                childCount: timelineData.length * 2 +
                    1, // Each phase split into two nodes, plus one for the last end time
              ),
            );
          } else {
            return const SliverFillRemaining(
              child: Text("No data available for this event."),
            );
          }
        } else {
          return SliverFillRemaining(
            child: Container(),
          );
        }
      },
    );
  }

  Widget buildTimelineTile(Map<String, dynamic> data, int index, int length,
      bool isStartNode, bool isLastNode) {
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    IndicatorStyle indicatorStyle;

    if (isStartNode || isLastNode) {
      indicatorStyle = IndicatorStyle(
        width: 30,
        color: getInterpolatedColor(rating),
        padding: const EdgeInsets.all(0),
      );
    } else {
      indicatorStyle = IndicatorStyle(
        width: 4,
        color: getInterpolatedColor(rating),
        indicator: Container(
          height: double.infinity,
          width: 4,
          color: getInterpolatedColor(rating),
        ),
      );
    }

    return SizedBox(
        height: 75,
        child: TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: (index == 0) & isStartNode,
          isLast: isLastNode, // Adjust isLast for the additional node
          indicatorStyle: indicatorStyle,
          beforeLineStyle: LineStyle(
            color: getInterpolatedColor(rating),
            thickness: 4,
          ),
          endChild: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.only(top: 0, left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isStartNode && !isLastNode) ...[
                  Text(formatter.format(data['startTime'].toDate()),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
                if (!isStartNode && !isLastNode) ...[
                  Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity: ${data['phaseName']}',
                              style: const TextStyle(color: AppColors.dark)),
                          Text(
                              'Location: ${data['phaseLocation'] ?? 'Location not specified'}',
                              style: const TextStyle(color: AppColors.dark)),
                        ],
                      )),
                ],
                if (isLastNode) ...[
                  const SizedBox(height: 4),
                  Text(formatter.format(data['endTime'].toDate()),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ],
            ),
          ),
        ));
  }
}
