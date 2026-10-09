import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/alarm_model.dart';
import '../../data/models/recurrence_rule.dart';

const weekdayShortLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String formatTimeOfDayMinutes(BuildContext context, int minutes) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
  );
}

String describeRecurrence(RecurrenceRule rule) {
  switch (rule.scheduleType) {
    case AlarmScheduleType.once:
      return DateFormat.MMMEd().format(rule.scheduledDate!);
    case AlarmScheduleType.daily:
      return 'Every day';
    case AlarmScheduleType.weekly:
      final days = rule.daysOfWeek.toList()..sort();
      if (days.length == 7) return 'Every day';
      if (_sameDays(days, const [1, 2, 3, 4, 5])) return 'Weekdays';
      if (_sameDays(days, const [6, 7])) return 'Weekends';
      return days.map((day) => weekdayShortLabels[day - 1]).join(', ');
    case AlarmScheduleType.intervalDays:
      return rule.intervalDays == 1
          ? 'Every day'
          : 'Every ${rule.intervalDays} days';
  }
}

/// "Off", "Not scheduled", or when the alarm rings next ("Today", "Tomorrow",
/// or a date).
String describeNextOccurrence(AlarmModel alarm, {DateTime? now}) {
  if (!alarm.isEnabled) return 'Off';
  final next = alarm.nextOccurrenceAt;
  if (next == null) return 'Not scheduled';
  final today = _dateOnly(now ?? DateTime.now());
  final days = _dateOnly(next).difference(today).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return DateFormat.MMMEd().format(next);
}

bool _sameDays(List<int> days, List<int> expected) =>
    days.length == expected.length &&
    Iterable<int>.generate(days.length).every((i) => days[i] == expected[i]);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
