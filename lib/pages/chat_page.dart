import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String eventID;
  const ChatPage({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Chat'),
      ),
      body: Center(
        child: Text('This is the Chat Page. Event ID: $eventID'),
      ),
    );
  }
}
