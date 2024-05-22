import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/database_puller.dart';

class DetailsCard extends StatelessWidget {
  final String eventID;

  const DetailsCard({super.key, required this.eventID});

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
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
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
                      Text('Host: ${snapshot.data!['hostName']}',
                          style: const TextStyle(fontSize: 12)),
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
