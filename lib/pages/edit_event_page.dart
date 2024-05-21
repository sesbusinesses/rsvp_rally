import 'package:flutter/material.dart';

class EditEventPage extends StatelessWidget {
  const EditEventPage({super.key});

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
