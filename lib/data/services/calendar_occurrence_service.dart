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

    for (final alarm in alarms.where((alarm) => alarm.isEnabled)) {
      var cursor = start.subtract(const Duration(minutes: 1));
      while (true) {
        final occurrence = alarm.recurrence.nextOccurrenceAfter(cursor);
        if (occurrence == null ||
            occurrence.isAfter(end.add(const Duration(days: 1)))) {
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
