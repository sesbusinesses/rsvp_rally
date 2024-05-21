import 'package:flutter/material.dart';

class PollPage extends StatelessWidget {
  const PollPage({super.key});

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
