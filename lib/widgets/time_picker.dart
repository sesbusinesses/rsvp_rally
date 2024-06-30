import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'custom_date_time_picker.dart';

Future<DateTime?> selectDateTime(
    BuildContext context, double rating, DateTime? initialTime) async {
  DateTime? selectedDateTime;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Expanded(
          child: AlertDialog(
        surfaceTintColor: getInterpolatedColor(rating),
        title: const Text('Select Date and Time'),
        content: SizedBox(
          width: double.maxFinite,
          child: CustomDateTimePicker(
            initialDateTime: initialTime ?? DateTime.now(),
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
              FocusScope.of(context).unfocus();
            },
            child: Text('OK',
                style: TextStyle(color: getInterpolatedColor(rating))),
          ),
        ],
      ));
    },
  );
  return selectedDateTime;
}
