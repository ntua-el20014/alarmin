import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/stopwatch_models.dart';

void main() {
  group('RecurrenceRule', () {
    test('calculates a one-time occurrence', () {
      final rule = RecurrenceRule(
        scheduleType: AlarmScheduleType.once,
        timeOfDay: 7 * 60 + 30,
        scheduledDate: DateTime(2026, 9, 21),
      );

      expect(
        rule.nextOccurrenceAfter(DateTime(2026, 9, 20, 23)),
        DateTime(2026, 9, 21, 7, 30),
      );
      expect(rule.nextOccurrenceAfter(DateTime(2026, 9, 21, 8)), isNull);
    });

    test('calculates the next daily occurrence', () {
      const rule = RecurrenceRule(
        scheduleType: AlarmScheduleType.daily,
        timeOfDay: 8 * 60,
      );

      expect(
        rule.nextOccurrenceAfter(DateTime(2026, 9, 21, 7)),
        DateTime(2026, 9, 21, 8),
      );
      expect(
        rule.nextOccurrenceAfter(DateTime(2026, 9, 21, 8)),
        DateTime(2026, 9, 22, 8),
      );
    });

    test('calculates the next selected weekday', () {
      final rule = RecurrenceRule(
        scheduleType: AlarmScheduleType.weekly,
        timeOfDay: 9 * 60,
        daysOfWeek: <int>{DateTime.monday, DateTime.wednesday},
      );

      expect(
        rule.nextOccurrenceAfter(DateTime(2026, 9, 21, 10)),
        DateTime(2026, 9, 23, 9),
      );
    });

    test('calculates every-N-days from its anchor date', () {
      final rule = RecurrenceRule(
        scheduleType: AlarmScheduleType.intervalDays,
        timeOfDay: 6 * 60,
        intervalDays: 2,
        scheduleStartDate: DateTime(2026, 9, 21),
      );

      expect(
        rule.nextOccurrenceAfter(DateTime(2026, 9, 22, 7)),
        DateTime(2026, 9, 23, 6),
      );
    });

    test('does not return an occurrence after the end date', () {
      final rule = RecurrenceRule(
        scheduleType: AlarmScheduleType.daily,
        timeOfDay: 8 * 60,
        scheduleEndDate: DateTime(2026, 9, 21),
      );

      expect(rule.nextOccurrenceAfter(DateTime(2026, 9, 21, 9)), isNull);
    });
  });

  test('app settings expose the roadmap defaults', () {
    const settings = AppSettings.defaults();

    expect(settings.timePickerStyle, TimePickerStyle.materialClock);
    expect(settings.isGroupedView, isFalse);
    expect(settings.defaultVibration, VibrationSetting.standard);
    expect(settings.defaultSnoozeDuration, const Duration(minutes: 10));
  });

  test('stopwatch sessions and laps have persistent identities', () {
    final startedAt = DateTime(2026, 9, 21, 10);
    final session = StopwatchSession(
      id: 'session-1',
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 2)),
      totalTimeMs: 120000,
      status: StopwatchSessionStatus.completed,
      createdAt: startedAt,
    );
    final lap = StopwatchLap(
      id: 'lap-1',
      sessionId: session.id,
      sequence: 1,
      elapsedAtLapMs: 60000,
      lapDurationMs: 60000,
      recordedAt: startedAt.add(const Duration(minutes: 1)),
    );

    expect(lap.sessionId, session.id);
    expect(session.status, StopwatchSessionStatus.completed);
  });
}
