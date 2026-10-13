import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
import 'package:alarmin/data/repositories/settings_repository.dart';
import 'package:alarmin/data/services/alarm_service.dart';
import 'package:alarmin/data/services/upcoming_alarm_notices.dart';

import 'support/fake_alarm_scheduler.dart';
import 'support/fake_upcoming_alarm_notices.dart';

void main() {
  late db.AppDatabase database;
  late FakeAlarmScheduler scheduler;
  late FakeUpcomingAlarmNotices notices;
  late AlarmRepository repository;
  late SettingsRepository settings;
  late AlarmService service;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 9, 21, 6);
    database = db.AppDatabase(NativeDatabase.memory());
    scheduler = FakeAlarmScheduler();
    notices = FakeUpcomingAlarmNotices();
    repository = AlarmRepository(database);
    settings = SettingsRepository(database);
    service = AlarmService(
      repository: repository,
      reincarnationRepository: ReincarnationRepository(database),
      settingsRepository: settings,
      scheduler: scheduler,
      notices: notices,
      now: () => now,
    );
  });

  tearDown(() async {
    await database.close();
    await scheduler.close();
  });

  test('announces the primary and follow-up occurrences', () async {
    final alarm = _alarm(reminders: 2);
    await service.save(alarm);

    final primary = notices.active[noticeSlotId(alarm.id, 0)]!;
    expect(primary.occurrence, DateTime(2026, 9, 21, 7));
    expect(primary.nativeIds, [
      primaryNativeId(alarm.id),
      reminderNativeId(alarm.id, DateTime(2026, 9, 21, 7), 1),
      reminderNativeId(alarm.id, DateTime(2026, 9, 21, 7), 2),
    ]);
    final followUp = notices.active[noticeSlotId(alarm.id, 1)]!;
    expect(followUp.occurrence, DateTime(2026, 9, 22, 7));
    expect(followUp.nativeIds.first, followUpNativeId(alarm.id));
  });

  test('a disabled or deleted alarm has no notices', () async {
    final alarm = _alarm();
    final saved = await service.save(alarm);
    await service.setEnabled(saved, false);
    expect(notices.active, isEmpty);

    await service.save(alarm);
    await service.delete(alarm);
    expect(notices.active, isEmpty);
  });

  test('the Settings switch turns the notices off', () async {
    await service.save(_alarm());
    await settings.save(
      (await settings.load()).copyWith(upcomingAlarmNotice: false),
    );

    await service.recover();

    expect(notices.active, isEmpty);
  });

  test('skipping a repeating alarm moves it to the next occurrence',
      () async {
    final alarm = _alarm(reminders: 1);
    await service.save(alarm);
    // What the notification's Skip button does natively.
    final notice = notices.active[noticeSlotId(alarm.id, 0)]!;
    notice.nativeIds.forEach(scheduler.active.remove);
    notices.pendingSkips.add(SkippedOccurrence(alarm.id, notice.occurrence));

    await service.recover();

    final saved = await repository.findById(alarm.id);
    expect(saved?.isEnabled, isTrue);
    expect(saved?.nextOccurrenceAt, DateTime(2026, 9, 22, 7));
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
    expect(
      scheduler.active.containsKey(
          reminderNativeId(alarm.id, DateTime(2026, 9, 21, 7), 1)),
      isFalse,
    );
    expect(notices.active[noticeSlotId(alarm.id, 0)]?.occurrence,
        DateTime(2026, 9, 22, 7));

    // Still skipped when the app recovers again before 07:00.
    await service.recover();
    expect((await repository.findById(alarm.id))?.nextOccurrenceAt,
        DateTime(2026, 9, 22, 7));
  });

  test('editing the alarm undoes the skip', () async {
    final alarm = _alarm();
    await service.save(alarm);
    notices.pendingSkips
        .add(SkippedOccurrence(alarm.id, DateTime(2026, 9, 21, 7)));
    await service.recover();

    await service.save((await repository.findById(alarm.id))!);

    expect((await repository.findById(alarm.id))?.nextOccurrenceAt,
        DateTime(2026, 9, 21, 7));
  });

  test('skipping a one-time alarm turns it off', () async {
    final alarm = _alarm(once: true);
    await service.save(alarm);
    notices.pendingSkips
        .add(SkippedOccurrence(alarm.id, DateTime(2026, 9, 21, 7)));

    await service.recover();

    final saved = await repository.findById(alarm.id);
    expect(saved?.isEnabled, isFalse);
    expect(scheduler.active, isEmpty);
    expect(notices.active, isEmpty);
  });
}

AlarmModel _alarm({bool once = false, int reminders = 0}) {
  final createdAt = DateTime(2026, 9, 20);
  return AlarmModel(
    id: 'alarm-1',
    title: 'Morning alarm',
    recurrence: once
        ? RecurrenceRule(
            scheduleType: AlarmScheduleType.once,
            timeOfDay: 7 * 60,
            scheduledDate: DateTime(2026, 9, 21),
          )
        : const RecurrenceRule(
            scheduleType: AlarmScheduleType.daily,
            timeOfDay: 7 * 60,
          ),
    isEnabled: true,
    deleteAfterUse: false,
    ringtone: 'classic',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: reminders,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
