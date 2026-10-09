import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/ringing_alarm.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
import 'package:alarmin/data/services/alarm_ring_handler.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/data/services/alarm_service.dart';

import 'support/fake_alarm_scheduler.dart';

void main() {
  late db.AppDatabase database;
  late FakeAlarmScheduler scheduler;
  late AlarmRepository alarmRepository;
  late ReincarnationRepository reincarnationRepository;
  late AlarmService service;
  late ValueNotifier<RingingAlarm?> ringing;
  late AlarmRingHandler handler;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 9, 21, 7);
    database = db.AppDatabase(NativeDatabase.memory());
    scheduler = FakeAlarmScheduler();
    alarmRepository = AlarmRepository(database);
    reincarnationRepository = ReincarnationRepository(database);
    service = AlarmService(
      repository: alarmRepository,
      reincarnationRepository: reincarnationRepository,
      scheduler: scheduler,
      now: () => now,
    );
    ringing = ValueNotifier<RingingAlarm?>(null);
    handler = AlarmRingHandler(
      alarmService: service,
      scheduler: scheduler,
      ringing: ringing,
    );
  });

  tearDown(() async {
    await handler.dispose();
    ringing.dispose();
    await database.close();
    await scheduler.close();
  });

  Future<AlarmModel> ringingAlarm({
    AlarmScheduleType type = AlarmScheduleType.daily,
    bool deleteAfterUse = false,
  }) async {
    now = DateTime(2026, 9, 21, 6);
    final alarm = await service.save(
      _alarm(recurrence: type, deleteAfterUse: deleteAfterUse),
    );
    now = DateTime(2026, 9, 21, 7);
    scheduler.ring(primaryNativeId(alarm.id));
    await handler.handleNativeRing(primaryNativeId(alarm.id));
    return alarm;
  }

  test('first snooze schedules the whole reincarnation chain', () async {
    final alarm = await ringingAlarm();

    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));

    expect(await scheduler.isRinging(primaryNativeId(alarm.id)), isFalse);
    expect(
      [
        for (var index = 0; index <= alarm.reincarnationCount; index++)
          scheduler.active[reincarnationNativeId(alarm.id, index)]?.dateTime,
      ],
      [
        now.add(const Duration(minutes: 10)),
        now.add(const Duration(minutes: 15)),
        now.add(const Duration(minutes: 20)),
      ],
    );
    final run = await reincarnationRepository.findActive(alarm.id);
    expect(run?.remainingCount, alarm.reincarnationCount);
    // The regular schedule moves on to tomorrow.
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
    expect(ringing.value, isNull);
  });

  test('each reincarnated ring decrements the remaining count once', () async {
    final alarm = await ringingAlarm();
    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));

    now = now.add(const Duration(minutes: 15));
    final reincarnation =
        await handler.handleNativeRing(reincarnationNativeId(alarm.id, 1));

    expect(reincarnation.canSnooze, isTrue);
    expect(
      (await reincarnationRepository.findActive(alarm.id))?.remainingCount,
      alarm.reincarnationCount - 1,
    );

    now = now.add(const Duration(minutes: 5));
    final last =
        await handler.handleNativeRing(reincarnationNativeId(alarm.id, 2));

    expect(last.canSnooze, isFalse);
    expect(
      (await reincarnationRepository.findActive(alarm.id))?.remainingCount,
      0,
    );
  });

  test('snoozing a reincarnated ring only silences it', () async {
    final alarm = await ringingAlarm();
    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));
    final scheduledCount = scheduler.scheduled.length;

    now = now.add(const Duration(minutes: 10));
    scheduler.ring(reincarnationNativeId(alarm.id, 0));
    await handler.snooze(alarm, nativeId: reincarnationNativeId(alarm.id, 0));

    expect(scheduler.scheduled, hasLength(scheduledCount));
    expect(scheduler.active.containsKey(reincarnationNativeId(alarm.id, 0)),
        isFalse);
    expect(scheduler.active.containsKey(reincarnationNativeId(alarm.id, 1)),
        isTrue);
  });

  test('dismiss ends the chain and keeps the recurring schedule', () async {
    final alarm = await ringingAlarm();
    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));

    await handler.dismiss(alarm);

    expect(await reincarnationRepository.findActive(alarm.id), isNull);
    expect(scheduler.active.keys, {
      primaryNativeId(alarm.id),
      followUpNativeId(alarm.id),
    });
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
  });

  test('delete-after-use removes a one-time alarm only on dismissal', () async {
    final alarm = await ringingAlarm(
      type: AlarmScheduleType.once,
      deleteAfterUse: true,
    );

    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));
    expect(await alarmRepository.findById(alarm.id), isNotNull);

    await handler.dismiss(alarm);

    expect(await alarmRepository.findById(alarm.id), isNull);
    expect(scheduler.active, isEmpty);
  });

  test('publishes the ringing alarm and clears it on a notification stop',
      () async {
    final alarm =
        await service.save(_alarm(recurrence: AlarmScheduleType.daily));
    handler.start();

    scheduler.ring(primaryNativeId(alarm.id));
    await _settle();
    expect(ringing.value?.alarm?.id, alarm.id);
    expect(ringing.value?.canSnooze, isTrue);

    now = DateTime(2026, 9, 21, 7, 1);
    scheduler.stopFromNotification(primaryNativeId(alarm.id));
    await _settle();
    expect(ringing.value, isNull);
  });

  test('timer and test alarms ring as standalone alarms', () async {
    handler.start();

    scheduler.ring(timerNativeId);
    await _settle();
    expect(ringing.value?.title, 'Timer finished');
    expect(ringing.value?.alarm, isNull);

    await handler.stop(ringing.value!);
    expect(scheduler.cancelled, contains(timerNativeId));
    expect(ringing.value, isNull);
  });
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

AlarmModel _alarm({
  required AlarmScheduleType recurrence,
  bool deleteAfterUse = false,
}) {
  final createdAt = DateTime(2026, 9, 20);
  final recurrenceRule = recurrence == AlarmScheduleType.once
      ? RecurrenceRule(
          scheduleType: recurrence,
          timeOfDay: 7 * 60,
          scheduledDate: DateTime(2026, 9, 21),
        )
      : RecurrenceRule(scheduleType: recurrence, timeOfDay: 7 * 60);
  return AlarmModel(
    id: 'alarm-ring',
    title: 'Ring test',
    recurrence: recurrenceRule,
    isEnabled: true,
    deleteAfterUse: deleteAfterUse,
    ringtone: 'classic',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
