import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/services/calendar_occurrence_service.dart';

/// Daylight-saving regressions. They only bite in a zone with clock changes
/// (e.g. Europe/Athens: 29 Mar and 25 Oct 2026) and pass trivially elsewhere.
void main() {
  RecurrenceRule interval(int days) => RecurrenceRule(
        scheduleType: AlarmScheduleType.intervalDays,
        timeOfDay: 7 * 60,
        intervalDays: days,
        scheduleStartDate: DateTime(2026, 1, 1),
      );

  test('daily alarms keep their wall-clock time across clock changes', () {
    const daily = RecurrenceRule(
      scheduleType: AlarmScheduleType.daily,
      timeOfDay: 7 * 60,
    );
    for (final dayBefore in [
      DateTime(2026, 3, 28, 8),
      DateTime(2026, 10, 24, 8)
    ]) {
      final next = daily.nextOccurrenceAfter(dayBefore)!;
      expect(next.hour, 7, reason: '$dayBefore -> $next');
      expect(next.day, dayBefore.day + 1);
    }
  });

  test('every-N-days alarms always move forward at 07:00', () {
    for (final days in [1, 2, 3, 7]) {
      final rule = interval(days);
      var cursor = DateTime(2026, 1, 1);
      while (cursor.isBefore(DateTime(2027, 1, 1))) {
        final next = rule.nextOccurrenceAfter(cursor)!;
        expect(next.isAfter(cursor), isTrue, reason: 'every $days: $cursor');
        expect(next.hour, 7, reason: 'every $days: $next');
        cursor = next;
      }
    }
  });

  test('the calendar expands a range spanning a clock change', () {
    final now = DateTime(2026, 9, 1);
    final alarm = AlarmModel(
      id: 'a',
      title: 'Every day',
      recurrence: interval(1),
      isEnabled: true,
      deleteAfterUse: false,
      ringtone: 'classic',
      vibration: VibrationSetting.standard,
      snoozeDuration: const Duration(minutes: 10),
      reincarnationCount: 0,
      reincarnationInterval: const Duration(minutes: 5),
      createdAt: now,
      updatedAt: now,
    );

    final events = CalendarOccurrenceService().occurrencesBetween(
      [alarm],
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 31),
    );

    expect(events, hasLength(12));
    expect(events.values.every((alarms) => alarms.length == 1), isTrue);
  });
}
