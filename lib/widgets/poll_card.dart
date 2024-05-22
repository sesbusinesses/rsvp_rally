import 'package:flutter/material.dart';

class PollCard extends StatelessWidget {
  final String eventID;
  final Map<String, dynamic> pollData;

  const PollCard({super.key, required this.eventID, required this.pollData});

  @override
  Widget build(BuildContext context) {
    // Generate widgets for each response type and the users who selected them
    List<Widget> responseWidgets = [];

    pollData['responses'].forEach((option, voters) {
      if (voters is List<dynamic>) {
        // Convert voters to a list of strings if necessary
        List<String> voterNames = List<String>.from(voters);
        // Add a text widget for each option showing the option and voters
        responseWidgets.add(Text("$option: ${voterNames.join(', ')}"));
      }
    });

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pollData['question'],
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...responseWidgets,
          ],
        ),
      ),
    );
  }
}
