import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/group_card.dart';
import 'package:rsvp_rally/pages/group_create_page.dart';

class GroupsPage extends StatelessWidget {
  final String username;
  final double userRating;

  const GroupsPage(
      {super.key, required this.username, required this.userRating});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Users')
              .doc(username)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CupertinoActivityIndicator(
                radius: 15,
              ));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                  child: Text('No groups found', style: AppColors.bodyStyle));
            } else {
              var userData = snapshot.data!;
              var groupIDs = List<String>.from(userData['Groups']);

              if (groupIDs.isEmpty) {
                return Center(
                    child: Text('No groups found', style: AppColors.bodyStyle));
              }

              return Padding(
                  padding: EdgeInsets.only(
                      top: 20,
                      left: screenSize.width * 0.075,
                      right: screenSize.width * 0.075),
                  child: ListView.builder(
                    itemCount: groupIDs.length,
                    itemBuilder: (context, index) {
                      return GroupCard(
                        groupID: groupIDs[index],
                        userRating: userRating,
                        username: username,
                      );
                    },
                  ));
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GroupCreatePage(
                        username: username,
                        rating: userRating,
                      )),
            );
          },
          backgroundColor: getInterpolatedColor(userRating),
          child: const Icon(Icons.add, color: AppColors.light),
        ));
  }
}
