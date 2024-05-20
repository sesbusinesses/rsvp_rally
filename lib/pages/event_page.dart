import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/event.dart';
import 'package:semicircle_indicator/semicircle_indicator.dart';


class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GoodPorn.to'),
        automaticallyImplyLeading: false,
      ),
      
      body: Center(
        child: SingleChildScrollView(
          // Enables scrolling
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                const SemicircularIndicator(
                color: Colors.orange,
                bottomPadding: 0,
                progress: 0.5,
                child: Text(
                  '50%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
              SizedBox(height: 20),
              EventWidget(screenSize: screenSize),
            ],
          ),
        ),
      ),
    );
  }
}
