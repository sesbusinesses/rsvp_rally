import 'package:flutter/material.dart';
import 'package:rsvp_rally/pages/friends_page.dart';
import 'package:rsvp_rally/pages/shop_page.dart';
import 'package:rsvp_rally/widgets/custom_switcher.dart';
import 'package:rsvp_rally/widgets/view_settings_button.dart';

class FriendsShopPageView extends StatefulWidget {
  final String username;
  final double rating;

  const FriendsShopPageView(
      {super.key, required this.username, required this.rating});

  @override
  _FriendsShopPageViewState createState() => _FriendsShopPageViewState();
}

class _FriendsShopPageViewState extends State<FriendsShopPageView> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomTabSwitcher(
          tabs: const ['Friends', 'Shop'],
          selectedIndex: _selectedIndex,
          onTabChanged: _onTabChanged,
          userRating: widget.rating,
          padding: const EdgeInsets.only(top: 8.0), // Adjust padding as needed
        ),
        actions: [
          ViewSettingsButton(
            username: widget.username,
            userRating: widget.rating,
          ),
        ],
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          FriendsPage(username: widget.username, rating: widget.rating),
          const ShopPage(),
        ],
      ),
    );
  }
}
