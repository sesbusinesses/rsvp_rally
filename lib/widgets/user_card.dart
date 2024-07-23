import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/models/user_card_model.dart';
import 'package:rsvp_rally/pages/friendInfo_page.dart';
import 'package:rsvp_rally/widgets/widebutton.dart';

class UserCard extends StatelessWidget {
  final String username;
  final bool smallVersion;
  final Icon? icon;
  final bool removePadding;
  final bool showUsername;
  final String viewerUsername;
  final bool isShop;
  final double height;
  final bool isClickable;

  const UserCard({
    super.key,
    required this.username,
    this.smallVersion = false,
    this.removePadding = false,
    this.showUsername = true,
    this.icon,
    this.viewerUsername = "",
    this.isShop = false,
    this.height = 80,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserCardModel(username, viewerUsername),
      child: _UserCardContent(
        smallVersion: smallVersion,
        removePadding: removePadding,
        showUsername: showUsername,
        icon: icon,
        isShop: isShop,
        height: height,
        isClickable: isClickable,
      ),
    );
  }
}

class _UserCardContent extends StatelessWidget {
  final bool smallVersion;
  final bool removePadding;
  final bool showUsername;
  final Icon? icon;
  final bool isShop;
  final double height;
  final bool isClickable;

  const _UserCardContent({
    required this.smallVersion,
    required this.removePadding,
    required this.showUsername,
    this.icon,
    required this.isShop,
    required this.height,
    required this.isClickable
  });

  void _navigateToFriendPage(BuildContext context, String username, double rating) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendInfoPage(username: username, rating: rating),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    final model = Provider.of<UserCardModel>(context);

    return FutureBuilder<void>(
      future: model.userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading user data'),
          );
        } else {
          var userData = model.userData;
          String firstName = userData['firstName'];
          String username = model.username;
          String lastName = userData['lastName'];
          String? profilePicBase64 = userData['profilePicBase64'];
          double rating = userData['rating'];

          return FutureBuilder<void>(
            future: model.friendsFuture,
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else if (friendSnapshot.hasError) {
                return const Center(
                  child: Text('Error loading friends list'),
                );
              } else {
                bool isFriend = model.isFriend;
                bool isRequestSent = model.isRequestSent;

                double finalHeight = isShop
                    ? height * 0.8
                    : (isFriend || isRequestSent || model.viewerUsername == "")
                        ? height
                        : 130;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Shop')
                      .doc('freakText')
                      .get(),
                  builder: (context, freakSnapshot) {
                    if (freakSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container();
                    } else if (freakSnapshot.hasError) {
                      return const Center(
                        child: Text('Error loading freak status'),
                      );
                    } else {
                      bool isFreak = false;
                      if (freakSnapshot.hasData && freakSnapshot.data != null) {
                        Map<String, dynamic> freakData =
                            freakSnapshot.data!.data() as Map<String, dynamic>;
                        isFreak = freakData[model.username] == true;
                      }

                      return GestureDetector(
                        onTap: isClickable ? () => _navigateToFriendPage(context, username, rating) : null,
                        child: Container(
                          width: screenSize.width * (isShop ? 0.68 : 0.85),
                          height: finalHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          margin: removePadding
                              ? const EdgeInsets.symmetric(vertical: 0)
                              : const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: getInterpolatedColor(rating),
                              width: AppColors.borderWidth,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      Stack(
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.shadow,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: isShop
                                                  ? (smallVersion ? 12 : 24)
                                                  : (smallVersion ? 15 : 30),
                                              backgroundImage:
                                                  profilePicBase64 != null
                                                      ? MemoryImage(
                                                          base64Decode(
                                                              profilePicBase64!))
                                                      : null,
                                              child: profilePicBase64 == null
                                                  ? Icon(
                                                      Icons.add,
                                                      size: isShop
                                                          ? (smallVersion
                                                              ? 12
                                                              : 24)
                                                          : (smallVersion
                                                              ? 15
                                                              : 30),
                                                      color:
                                                          AppColors.accentDark,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          if (!smallVersion)
                                            Positioned(
                                              bottom: -3,
                                              right: -6,
                                              child: CircleAvatar(
                                                radius: isShop ? 14 : 18,
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Image.asset(
                                                  getEmoji(
                                                      rating), // Displaying the appropriate emoji image
                                                  width: isShop ? 16 : 20,
                                                  height: isShop ? 16 : 20,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$firstName $lastName",
                                              style:
                                                  AppColors.bodyStyle.copyWith(
                                                fontSize: isShop ? 12 : 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (showUsername && !smallVersion)
                                              Text(
                                                model.username,
                                                style: AppColors.usernameStyle
                                                    .copyWith(
                                                  fontSize: isShop ? 10 : 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (icon != null) icon!,
                                      if (icon != null)
                                        const SizedBox(width: 15),
                                    ],
                                  ),
                                  if (model.viewerUsername != "" &&
                                      !isFriend &&
                                      !isRequestSent &&
                                      !isShop)
                                    Container(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: WideButton(
                                        buttonText: "Add Friend",
                                        onPressed: () {
                                          model.addFriend(
                                              context, model.username);
                                        },
                                        rating: rating,
                                        smallVersion: true,
                                      ),
                                    ),
                                ],
                              ),
                              if (isFreak)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Text(
                                    "𝓯𝓻𝓮𝓪𝓴𝔂",
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.bold,
                                      fontSize: isShop ? 14 : 18,
                                      color: getInterpolatedColor(rating),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}
