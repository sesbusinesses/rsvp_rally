import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'package:rsvp_rally/widgets/user_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopCard extends StatefulWidget {
  final double rating;
  final double requiredRating;
  final String username;
  final String displayUsername;
  final bool isFreak;

  const ShopCard({
    Key? key,
    required this.rating,
    required this.requiredRating,
    required this.username,
    required this.displayUsername,
    this.isFreak = false,
  }) : super(key: key);

  @override
  _ShopCardState createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard> {
  bool isSwitchOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFreak) {
      _fetchToggleState();
    }
  }

  Future<void> _fetchToggleState() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Shop')
          .doc('freakText')
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey(widget.username)) {
          setState(() {
            isSwitchOn = data[widget.username];
          });
        }
      }
    } catch (e) {
      print('Error fetching toggle state: $e');
    }
  }

  Future<void> _updateToggleState(bool value) async {
    if (widget.isFreak) {
      try {
        await FirebaseFirestore.instance
            .collection('Shop')
            .doc('freakText')
            .update({widget.username: value});
      } catch (e) {
        print('Error updating toggle state: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = getInterpolatedColor(widget.rating);
    bool isToggleEnabled = widget.rating >= widget.requiredRating;
    Color switchColor = isSwitchOn ? borderColor : Colors.grey;

    if (!isToggleEnabled && isSwitchOn) {
      setState(() {
        isSwitchOn = false;
      });
      _updateToggleState(false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: borderColor,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: isSwitchOn,
                      onChanged: isToggleEnabled
                          ? (value) {
                              setState(() {
                                isSwitchOn = value;
                              });
                              _updateToggleState(value);
                            }
                          : null,
                      activeColor: isToggleEnabled ? switchColor : Colors.grey,
                      inactiveThumbColor: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isToggleEnabled
                          ? 'Get your FREAK on!'
                          : 'You need ${widget.requiredRating} rating',
                      textAlign: TextAlign.center,
                      style: AppColors.titleStyle.copyWith(fontSize: 19),
                    ),
                  ),
                  const SizedBox(width: 40), // To balance the spacing
                ],
              ),
            ),
            UserCard(
              username: widget.displayUsername,
              isShop: true,
            ),
          ],
        ),
      ),
    );
  }
}
