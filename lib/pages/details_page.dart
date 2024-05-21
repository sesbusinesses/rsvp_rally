import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String eventID;
  const DetailsPage({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: const Center(
        child: Text('This is the Details Page.'),
      ),
    );
  }
}
