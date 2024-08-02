import 'package:flutter/material.dart';
import 'package:rsvp_rally/widgets/shop_card.dart';

class ShopPage extends StatelessWidget {
  final double rating;
  final String username;

  const ShopPage({
    Key? key,
    required this.rating,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  ShopCard(
                    rating: rating,
                    
                    requiredRating: 0.9,
                    username: username,
                    displayUsername: 'username', // Replace with actual username to display
                    isFreak: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
