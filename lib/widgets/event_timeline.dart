import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Ensure this path is correct
// Firestore timestamp handling

class EventTimeline extends StatelessWidget {
  final String eventID;

  const EventTimeline({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTimeline(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var timelineData = snapshot.data!;
            // Adjust the count to handle an extra node for the end time
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < timelineData.length) {
                    final data = timelineData[index];
                    return buildTimelineTile(
                        data, index, timelineData.length, false);
                  } else {
                    // Handling the extra node for displaying the end time of the last phase
                    final lastData = timelineData.last;
                    return buildTimelineTile(
                        lastData, index, timelineData.length, true);
                  }
                },
                childCount:
                    timelineData.length + 1, // Plus one for the last end time
              ),
            );
          } else {
            return const SliverFillRemaining(
              child: Text("No data available for this event."),
            );
          }
        } else {
          return const SliverFillRemaining(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget buildTimelineTile(
      Map<String, dynamic> data, int index, int length, bool isLastNode) {
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.2,
      isFirst: index == 0,
      isLast: isLastNode, // Adjust isLast for the additional node
      indicatorStyle: const IndicatorStyle(
        width: 30,
        color: Colors.blue,
        padding: EdgeInsets.all(0),
      ),
      beforeLineStyle: const LineStyle(
        color: Colors.blue,
        thickness: 4,
      ),
      endChild: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.only(top: 50, left: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLastNode) ...[
              Text(data['startTime'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(data['phaseName']),
              Text(data['phaseLocation'] ?? 'Location not specified'),
            ],
            if (isLastNode) ...[
              const SizedBox(height: 4),
              Text('${data['endTime'] ?? 'Ongoing'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16))
            ],
          ],
        ),
      ),
    );
  }
}
