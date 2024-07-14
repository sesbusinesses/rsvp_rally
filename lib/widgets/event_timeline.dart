import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
  final String username;

  const EventTimeline({
    super.key,
    required this.eventID,
    required this.rating,
    required this.username,
  });

  Future<bool> hasRSVPdYes(String phaseName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot eventDoc =
          await firestore.collection('Events').doc(eventID).get();
      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> polls = eventData['Polls'] ?? {};

        if (polls.containsKey('RSVP for $phaseName')) {
          var responses = polls['RSVP for $phaseName'];
          return responses['Yes'] != null &&
              responses['Yes'].contains(username);
        }
      }
    } catch (e) {
      log("Error fetching event or processing data: $e");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTimeline(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var timelineData = snapshot.data!;
            return ListView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // Disable inner scrolling
              shrinkWrap: true,
              itemCount: timelineData.length * 2 + 1,
              itemBuilder: (context, index) {
                final int phaseIndex = index ~/ 2;
                final bool isStartNode = index % 2 == 0;
                if (phaseIndex < timelineData.length) {
                  final data = timelineData[phaseIndex];
                  return FutureBuilder<bool>(
                    future: hasRSVPdYes(data['phaseName']),
                    builder: (context, rsvpSnapshot) {
                      if (rsvpSnapshot.connectionState ==
                          ConnectionState.done) {
                        bool rsvpYes = rsvpSnapshot.data ?? false;
                        return buildTimelineTile(data, phaseIndex,
                            timelineData.length, isStartNode, false, rsvpYes);
                      } else {
                        return const Center(
                            child: CupertinoActivityIndicator(radius: 15));
                      }
                    },
                  );
                } else {
                  final lastData = timelineData.last;
                  return FutureBuilder<bool>(
                    future: hasRSVPdYes(lastData['phaseName']),
                    builder: (context, rsvpSnapshot) {
                      if (rsvpSnapshot.connectionState ==
                          ConnectionState.done) {
                        bool rsvpYes = rsvpSnapshot.data ?? false;
                        return buildTimelineTile(lastData, phaseIndex,
                            timelineData.length, false, true, rsvpYes);
                      } else {
                        return const Center(
                            child: CupertinoActivityIndicator(radius: 15));
                      }
                    },
                  );
                }
              },
            );
          } else {
            return Center(
              child: Text(
                "No data available for this event.",
                style: AppColors.bodyStyle,
              ),
            );
          }
        } else {
          return const Center(
            child: CupertinoActivityIndicator(
              radius: 15,
            ),
          );
        }
      },
    );
  }

  Widget buildTimelineTile(Map<String, dynamic> data, int index, int length,
      bool isStartNode, bool isLastNode, bool rsvpYes) {
    final DateFormat dateFormatter = DateFormat('MMM d, yyyy');
    final DateFormat timeFormatter = DateFormat('h:mm a');
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
        lineXY: 0.1,
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
                        startTime.day == endTime.day
                            ? timeFormatter.format(startTime)
                            : '${dateFormatter.format(startTime)} ${timeFormatter.format(startTime)}',
                        style: AppColors.darkDateStyle,
                      ),
                    if (!isStartNode && !isLastNode)
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['phaseName']}',
                              style: AppColors.bodyStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (rsvpYes && data['phaseLocation'] != null)
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  text: TextSpan(
                                    text: '${data['phaseLocation']}',
                                    style: AppColors.linkStyle,
                                  ),
                                ),
                              )
                            else
                              RichText(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  text: TextSpan(
                                    text: 'RSVP \'Yes\' for the location',
                                    style: AppColors.bodyStyle,
                                  )),
                          ],
                        ),
                      ),
                    if (isLastNode)
                      Text(
                        startTime.day == endTime.day
                            ? timeFormatter.format(endTime)
                            : '${dateFormatter.format(endTime)} ${timeFormatter.format(endTime)}',
                        style: AppColors.darkDateStyle,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
