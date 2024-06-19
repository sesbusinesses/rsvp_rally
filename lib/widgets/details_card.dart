import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/database_puller.dart';

class DetailsCard extends StatelessWidget {
  final double rating;
  final String eventID;

  const DetailsCard({super.key, required this.eventID, required this.rating});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchEventDetails(eventID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 15, horizontal: screenSize.width * 0.075),
              child: Container(
                width: screenSize.width * 0.85,
                decoration: BoxDecoration(
                  color: AppColors.light, // Dark background color
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: getInterpolatedColor(rating),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text('${snapshot.data!['eventName']} Details',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        'Host: ${snapshot.data!['hostName']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.accentDark),
                      ),
                      const SizedBox(height: 15),
                      Text(snapshot.data!['details'],
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16)),
            );
          }
        }
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
