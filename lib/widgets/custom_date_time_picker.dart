import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rsvp_rally/models/colors.dart'; // Assuming this is where getInterpolatedColor is defined

class CustomDateTimePicker extends StatefulWidget {
  final Function(DateTime) onDateTimeSelected;
  final DateTime initialDateTime;
  final double rating;

  const CustomDateTimePicker({
    super.key,
    required this.onDateTimeSelected,
    required this.initialDateTime,
    required this.rating,
  });

  @override
  _CustomDateTimePickerState createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late DateTime selectedDate;
  late int selectedHour;
  late int selectedMinute;
  late bool isAm;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDateTime;
    selectedHour = selectedDate.hour % 12 == 0 ? 12 : selectedDate.hour % 12;
    selectedMinute = (selectedDate.minute ~/ 5) * 5;
    isAm = selectedDate.hour < 12;
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        isAm ? selectedHour % 12 : (selectedHour % 12) + 12,
        selectedMinute,
      );
    });
    widget.onDateTimeSelected(selectedDate);
  }

  void _onTimeChanged(int hour, int minute, bool isAm) {
    setState(() {
      selectedHour = hour;
      selectedMinute = minute;
      this.isAm = isAm;
      selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        isAm ? hour % 12 : (hour % 12) + 12,
        minute,
      );
    });
    widget.onDateTimeSelected(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = getInterpolatedColor(widget.rating);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime(2101),
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selectedDay, focusedDay) {
            _onDateSelected(selectedDay);
          },
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(color: Colors.black),
            selectedDecoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: const TextStyle(color: AppColors.dark),
            holidayTextStyle: const TextStyle(color: AppColors.dark),
            defaultTextStyle: const TextStyle(color: Colors.black),
          ),
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            formatButtonTextStyle: const TextStyle(color: Colors.white),
            titleTextStyle:
                const TextStyle(color: AppColors.dark, fontSize: 16.0),
            leftChevronIcon: const Icon(
              Icons.chevron_left,
              color: AppColors.dark,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right,
              color: AppColors.dark,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: AppColors.dark),
            weekdayStyle: TextStyle(color: AppColors.dark),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 150.0,
          child: Row(
            children: [
              // Hour Picker
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                      initialItem: selectedHour - 1),
                  onSelectedItemChanged: (int index) {
                    _onTimeChanged(index + 1, selectedMinute, isAm);
                  },
                  children: List<Widget>.generate(12, (int index) {
                    return Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppColors.dark),
                      ),
                    );
                  }),
                ),
              ),
              const Text(':'),
              // Minute Picker
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                      initialItem: selectedMinute ~/ 5),
                  onSelectedItemChanged: (int index) {
                    _onTimeChanged(selectedHour, index * 5, isAm);
                  },
                  children: List<Widget>.generate(12, (int index) {
                    return Center(
                      child: Text(
                        '${index * 5}'.padLeft(2, '0'),
                        style: const TextStyle(color: AppColors.dark),
                      ),
                    );
                  }),
                ),
              ),
              // AM/PM Picker
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController:
                      FixedExtentScrollController(initialItem: isAm ? 0 : 1),
                  onSelectedItemChanged: (int index) {
                    _onTimeChanged(selectedHour, selectedMinute, index == 0);
                  },
                  children: const <Widget>[
                    Center(child: Text('AM')),
                    Center(child: Text('PM')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
