import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/services/calendar_occurrence_service.dart';

void main() {
  final service = CalendarOccurrenceService();
  final start = DateTime(2026, 9, 21);
  final end = DateTime(2026, 9, 27, 23, 59);

  test('expands daily and weekly alarms within a bounded range', () {
    final alarms = [
      _alarm(
        id: 'daily',
        recurrence: const RecurrenceRule(
          scheduleType: AlarmScheduleType.daily,
          timeOfDay: 7 * 60,
        ),
      ),
      _alarm(
        id: 'weekly',
        recurrence: RecurrenceRule(
          scheduleType: AlarmScheduleType.weekly,
          timeOfDay: 8 * 60,
          daysOfWeek: <int>{DateTime.monday, DateTime.friday},
        ),
      ),
    ];

    final events = service.occurrencesBetween(alarms, start, end);

    expect(events[DateTime(2026, 9, 21)], hasLength(2));
    expect(events[DateTime(2026, 9, 25)], hasLength(2));
    expect(events[DateTime(2026, 9, 23)], hasLength(1));
  });

  test('includes one-time alarms and excludes disabled alarms', () {
    final alarms = [
      _alarm(
        id: 'once',
        recurrence: RecurrenceRule(
          scheduleType: AlarmScheduleType.once,
          timeOfDay: 9 * 60,
          scheduledDate: DateTime(2026, 9, 24),
        ),
      ),
      _alarm(
        id: 'disabled',
        isEnabled: false,
        recurrence: const RecurrenceRule(
          scheduleType: AlarmScheduleType.daily,
          timeOfDay: 10 * 60,
        ),
      ),
    ];

    final events = service.occurrencesBetween(alarms, start, end);

    expect(events[DateTime(2026, 9, 24)]?.single.id, 'once');
    expect(
      events.values.expand((items) => items).map((alarm) => alarm.id),
      isNot(contains('disabled')),
    );
  });
}

AlarmModel _alarm({
  required String id,
  required RecurrenceRule recurrence,
  bool isEnabled = true,
}) {
  final now = DateTime(2026, 9, 20);
  return AlarmModel(
    id: id,
    title: id,
    recurrence: recurrence,
    isEnabled: isEnabled,
    deleteAfterUse: false,
    ringtone: 'default',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: now,
    updatedAt: now,
  );
}
