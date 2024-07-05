import 'package:flutter/material.dart';
import 'package:rsvp_rally/models/colors.dart';
import 'custom_date_time_picker.dart';

Future<DateTime?> selectDateTime(
    BuildContext context, double rating, DateTime? initialTime) async {
  DateTime? selectedDateTime;

  // Close the keyboard if open
  FocusScope.of(context).unfocus();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        surfaceTintColor: getInterpolatedColor(rating),
        title: Text(
          'Select Date and Time',
          style: AppColors.titleStyle,
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: CustomDateTimePicker(
              initialDateTime: initialTime ?? DateTime.now(),
              onDateTimeSelected: (DateTime dateTime) {
                selectedDateTime = dateTime;
              },
              rating: rating,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FocusScope.of(context).unfocus();
            },
            child: Text('OK',
                style: AppColors.buttonStyle
                    .copyWith(color: getInterpolatedColor(rating))),
          ),
        ],
      );
    },
  );

  return selectedDateTime;
}
