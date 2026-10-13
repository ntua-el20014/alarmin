import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/ringtone.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
import 'package:alarmin/data/repositories/settings_repository.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/data/services/alarm_service.dart';

import 'support/fake_alarm_scheduler.dart';

void main() {
  late db.AppDatabase database;
  late FakeAlarmScheduler scheduler;
  late AlarmRepository repository;
  late AlarmService service;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 9, 21, 6);
    database = db.AppDatabase(NativeDatabase.memory());
    scheduler = FakeAlarmScheduler();
    repository = AlarmRepository(database);
    service = AlarmService(
      repository: repository,
      reincarnationRepository: ReincarnationRepository(database),
      scheduler: scheduler,
      now: () => now,
    );
  });

  tearDown(() async {
    await database.close();
    await scheduler.close();
  });

  test('saves and schedules the next two occurrences of a recurrence',
      () async {
    final alarm = _alarm();

    await service.save(alarm);

    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 21, 7));
    expect(scheduler.active[followUpNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
    expect((await repository.findById(alarm.id))?.nextOccurrenceAt,
        DateTime(2026, 9, 21, 7));
  });

  test('a gentle alarm fades in, a normal one does not', () async {
    await service.save(_alarm().copyWith(wakeStyle: WakeStyle.gentle));
    expect(scheduler.active[primaryNativeId('alarm-1')]?.fadeDuration,
        gentleFadeDuration);

    await service.save(_alarm());
    expect(scheduler.active[primaryNativeId('alarm-1')]?.fadeDuration,
        Duration.zero);
  });

  test('schedules a bundled ringtone even for legacy ringtone values',
      () async {
    await service.save(_alarm(ringtone: 'assets/audio/default.mp3'));

    final request = scheduler.scheduled.first;
    expect(Ringtone.resolve(request.ringtone), Ringtone.fallback);
  });

  test('an alarm on "Default" plays the Settings sound, others their own',
      () async {
    final settingsRepository = SettingsRepository(database);
    await settingsRepository.save(
      (await settingsRepository.load()).copyWith(defaultRingtone: 'gentle'),
    );
    final withSettings = AlarmService(
      repository: repository,
      reincarnationRepository: ReincarnationRepository(database),
      settingsRepository: settingsRepository,
      scheduler: scheduler,
      now: () => now,
    );

    await withSettings.save(_alarm(ringtone: Ringtone.followDefault));
    expect(scheduler.active[primaryNativeId('alarm-1')]?.ringtone, 'gentle');

    await withSettings.save(_alarm(ringtone: 'digital'));
    expect(scheduler.active[primaryNativeId('alarm-1')]?.ringtone, 'digital');
  });

  test('disabling an alarm cancels its native alarms', () async {
    final alarm = _alarm();
    await service.save(alarm);

    await service.setEnabled(alarm, false);

    expect(scheduler.active, isEmpty);
    expect((await repository.findById(alarm.id))?.isEnabled, isFalse);
  });

  test('recovers enabled alarms missing from the native schedule', () async {
    await service.save(_alarm());
    scheduler.active.clear();

    await service.recover();

    expect(scheduler.active[primaryNativeId('alarm-1')]?.dateTime,
        DateTime(2026, 9, 21, 7));
  });

  test('recovery never stops an alarm that is ringing', () async {
    final alarm = _alarm();
    await service.save(alarm);
    now = DateTime(2026, 9, 21, 7, 0, 30);
    scheduler.ring(primaryNativeId(alarm.id));
    scheduler.cancelled.clear();

    await service.recover();

    expect(scheduler.cancelled, isEmpty);
    expect(await scheduler.isRinging(primaryNativeId(alarm.id)), isTrue);
  });

  test('recovery leaves an alarm that is due this moment alone', () async {
    final alarm = _alarm();
    await service.save(alarm);
    now = DateTime(2026, 9, 21, 7, 0, 10);
    scheduler.cancelled.clear();

    await service.recover();

    expect(scheduler.cancelled, isEmpty);
  });

  test('stopping a recurring alarm from its notification reschedules it',
      () async {
    final alarm = _alarm();
    await service.save(alarm);
    now = DateTime(2026, 9, 21, 7, 2);
    scheduler.ring(primaryNativeId(alarm.id));

    scheduler.stopFromNotification(primaryNativeId(alarm.id));
    await service.handleNativeUpdate(primaryNativeId(alarm.id));

    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
    expect((await repository.findById(alarm.id))?.nextOccurrenceAt,
        DateTime(2026, 9, 22, 7));
  });

  test('stopping a one-time alarm from its notification disables it', () async {
    final alarm = _alarm(once: true);
    await service.save(alarm);
    now = DateTime(2026, 9, 21, 7, 2);
    scheduler.ring(primaryNativeId(alarm.id));

    scheduler.stopFromNotification(primaryNativeId(alarm.id));
    await service.handleNativeUpdate(primaryNativeId(alarm.id));

    final saved = await repository.findById(alarm.id);
    expect(saved?.isEnabled, isFalse);
    expect(saved?.nextOccurrenceAt, isNull);
  });

  test('update events for a future alarm do not reschedule it', () async {
    final alarm = _alarm();
    await service.save(alarm);
    final scheduledCount = scheduler.scheduled.length;

    await service.handleNativeUpdate(primaryNativeId(alarm.id));

    expect(scheduler.scheduled, hasLength(scheduledCount));
  });

  test('maps a stable valid native id from a domain id', () {
    expect(nativeAlarmId('alarm-1'), nativeAlarmId('alarm-1'));
    expect(nativeAlarmId('alarm-1'), isNot(0));
    expect(nativeAlarmId('alarm-1'), isNot(-1));
    expect(
      {
        primaryNativeId('alarm-1'),
        followUpNativeId('alarm-1'),
        snoozeNativeId('alarm-1'),
        reminderNativeId('alarm-1', DateTime(2026, 9, 21, 7), 1),
      },
      hasLength(4),
    );
    expect(primaryNativeId('alarm-1'), isNot(timerNativeId));
  });
}

AlarmModel _alarm({bool once = false, String ringtone = 'classic'}) {
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
    ringtone: ringtone,
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 0,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
