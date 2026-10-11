import '../models/alarm_model.dart';

class CalendarOccurrenceService {
  Map<DateTime, List<AlarmModel>> occurrencesBetween(
    List<AlarmModel> alarms,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = _dateOnly(rangeStart);
    final end = _dateOnly(rangeEnd);
    final events = <DateTime, List<AlarmModel>>{};

    final rangeLimit = DateTime(end.year, end.month, end.day + 1);
    for (final alarm in alarms.where((alarm) => alarm.isEnabled)) {
      var cursor = start.subtract(const Duration(minutes: 1));
      // At most one occurrence per day; the cap and the "must move forward"
      // check make sure a recurrence bug can never hang the UI again.
      final maxSteps = end.difference(start).inDays + 3;
      for (var step = 0; step < maxSteps; step++) {
        final occurrence = alarm.recurrence.nextOccurrenceAfter(cursor);
        if (occurrence == null ||
            !occurrence.isAfter(cursor) ||
            occurrence.isAfter(rangeLimit)) {
          break;
        }
        if (!occurrence.isBefore(start)) {
          events.putIfAbsent(_dateOnly(occurrence), () => []).add(alarm);
        }
        cursor = occurrence;
      }
    }

    return events;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
