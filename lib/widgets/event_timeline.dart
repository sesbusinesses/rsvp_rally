import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/bracket_painter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:rsvp_rally/models/database_puller.dart'; // Ensure this path is correct
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    final lastData = timelineData.last;
                    return buildTimelineTile(
                        lastData, phaseIndex, timelineData.length, false, true);
                  }
                },
                childCount: timelineData.length * 2 + 1,
              ),
            );
          } else {
            return const SliverFillRemaining(
              child: Text("No data available for this event."),
            );
          }
        } else {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget buildTimelineTile(Map<String, dynamic> data, int index, int length,
      bool isStartNode, bool isLastNode) {
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    final currentTime = DateTime.now();
    final startTime = data['startTime'].toDate();
    final endTime = data['endTime'].toDate();

    bool isCurrentPhase =
        currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
    bool isPastPhase = currentTime.isAfter(endTime);
    bool isFuturePhase = currentTime.isBefore(startTime);

    IndicatorStyle indicatorStyle;

    if (isStartNode || isLastNode) {
      indicatorStyle = IndicatorStyle(
          width: 30,
          padding: const EdgeInsets.all(0),
          indicator: isFuturePhase || (isCurrentPhase && isLastNode)
              ? Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                        color: getInterpolatedColor(rating),
                        width: AppColors.borderWidth),
                  ),
                )
              : Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getInterpolatedColor(rating),
                    border: Border.all(
                        color: getInterpolatedColor(rating),
                        width: AppColors.borderWidth),
                  ),
                ),
          drawGap: isFuturePhase || (isCurrentPhase && isLastNode));
    } else if (isCurrentPhase) {
      indicatorStyle = IndicatorStyle(
        width: 15,
        padding: const EdgeInsets.all(0),
        indicator: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getInterpolatedColor(rating),
            border: Border.all(
                color: getInterpolatedColor(rating),
                width: AppColors.borderWidth),
          ),
          child: const Icon(Icons.play_arrow, color: AppColors.light, size: 10),
        ),
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
        height: 60,
        child: TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.15,
          isFirst: (index == 0) & isStartNode,
          isLast: isLastNode,
          indicatorStyle: indicatorStyle,
          beforeLineStyle: LineStyle(
            color: getInterpolatedColor(rating),
            thickness: 4,
          ),
          endChild: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.only(left: 10),
            color: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (!isStartNode && !isLastNode)
                  CustomPaint(
                    size: const Size(20, 100),
                    painter: BracketPainter(getInterpolatedColor(rating)),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isStartNode && !isLastNode)
                        Text(
                          formatter.format(data['startTime'].toDate()),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      if (!isStartNode && !isLastNode)
                        Padding(
                          padding: const EdgeInsets.only(left: 5, right: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['phaseName']}',
                                style: const TextStyle(color: AppColors.dark),
                              ),
                              if (data['phaseLocation'] != null)
                                GestureDetector(
                                  onTap: () async {
                                    final String url =
                                        'https://www.google.com/maps/search/?api=1&query=${data['phaseLocation']}';
                                    final Uri uri = Uri.parse(url);
                                    if (!await launchUrl(uri,
                                        mode: LaunchMode.externalApplication)) {
                                      throw 'Could not launch $uri';
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: '${data['phaseLocation']}',
                                      style: const TextStyle(
                                          color: AppColors.link),
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  'Location not specified',
                                  style: TextStyle(color: AppColors.dark),
                                ),
                            ],
                          ),
                        ),
                      if (isLastNode) const SizedBox(height: 4),
                      if (isLastNode)
                        Text(
                          formatter.format(data['endTime'].toDate()),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
