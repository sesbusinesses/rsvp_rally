import 'package:flutter/material.dart';

class EditEventPage extends StatelessWidget {
  final String eventID;
  const EditEventPage({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
      ),
      body: const Center(
        child: Text('This is the Edit Page.'),
      ),
    );
  }
}
