import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'custom_date_time_picker.dart';

Future<DateTime?> selectDateTime(BuildContext context, double rating) async {
  DateTime? selectedDateTime;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        surfaceTintColor: getInterpolatedColor(rating),
        title: const Text('Select Date and Time'),
        content: SizedBox(
          width: double.maxFinite,
          child: CustomDateTimePicker(
            initialDateTime: DateTime.now(),
            onDateTimeSelected: (DateTime dateTime) {
              selectedDateTime = dateTime;
            },
            rating: rating,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK',
                style: TextStyle(color: getInterpolatedColor(rating))),
          ),
        ],
      );
    },
  );
  return selectedDateTime;
}
