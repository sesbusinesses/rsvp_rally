import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:rsvp_rally/models/database_puller.dart';

class EventTimeline extends StatelessWidget {
  final String eventID;

  const EventTimeline({Key? key, required this.eventID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTimeline(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else if (snapshot.hasData) {
          var timelineData = snapshot.data!;
          // Adding the last node logic into data processing for simplicity in ListView.builder
          if (timelineData.isNotEmpty) {
            timelineData.add({'endTime': timelineData.last['endTime']});
          }
          return ListView.builder(
            itemCount: timelineData.length,
            itemBuilder: (context, index) {
              final data = timelineData[index];
              return buildTimelineTile(data, index, timelineData.length);
            },
          );
        } else {
          return const Text("No data available for this event.");
        }
      },
    );
  }

  Widget buildTimelineTile(Map<String, dynamic> data, int index, int length) {
    bool isLast = index == length - 1;
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.2,
      isFirst: index == 0,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 30,
        color: Colors.blue,
        padding: const EdgeInsets.all(8),
      ),
      beforeLineStyle: const LineStyle(
        color: Colors.blue,
        thickness: 4,
      ),
      endChild: Container(
        constraints: const BoxConstraints(maxHeight: 140),
        padding: const EdgeInsets.only(top: 50, left: 8),
        child: isLast
            ? Text(data['endTime'],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['startTime'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 20),
                  Text(data['phaseName']),
                  Text(data['phaseLocation']),
                ],
              ),
      ),
    );
  }
}
