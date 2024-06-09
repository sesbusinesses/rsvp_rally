import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:rsvp_rally/models/colors.dart';

Future<DateTime?> selectDateTime(BuildContext context, rating) async {
  final DateTime? pickedDateTime = await showOmniDateTimePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2101),
    is24HourMode: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: getInterpolatedColor(rating),
        onPrimary: AppColors.dark,
        onSurface: AppColors.dark,
        background: Colors.white,
        surfaceTint: getInterpolatedColor(rating),
      ),
    ),
  );

  return pickedDateTime;
}
