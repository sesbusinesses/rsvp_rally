import 'package:flutter/material.dart';

class PollPage extends StatelessWidget {
  final String eventID;
  const PollPage({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Poll'),
      ),
      body: const Center(
        child: Text('This is the Poll Page.'),
      ),
    );
  }
}
