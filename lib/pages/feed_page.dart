import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Feed Content Coming Soon!',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
