import 'package:flutter/material.dart';

class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'My Feed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Feed Content Here',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
