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

  final sevenAm = DateTime(2026, 9, 21, 7);
  int reminder(AlarmModel alarm, int index, {DateTime? occurrence}) =>
      reminderNativeId(alarm.id, occurrence ?? sevenAm, index);

  Future<AlarmModel> ringingAlarm({
    AlarmScheduleType type = AlarmScheduleType.daily,
    bool deleteAfterUse = false,
    int reminders = 2,
  }) async {
    now = DateTime(2026, 9, 21, 6);
    final alarm = await service.save(
      _alarm(
        recurrence: type,
        deleteAfterUse: deleteAfterUse,
        reminders: reminders,
      ),
    );
    now = sevenAm;
    scheduler.ring(primaryNativeId(alarm.id));
    await handler.handleNativeRing(primaryNativeId(alarm.id));
    return alarm;
  }

  Future<void> ringAt(int nativeId, DateTime at) async {
    now = at;
    scheduler.ring(nativeId);
    await handler.handleNativeRing(nativeId);
  }

  test('saving schedules every occurrence with its reminders up front',
      () async {
    now = DateTime(2026, 9, 21, 6);
    final alarm = await service.save(
      _alarm(recurrence: AlarmScheduleType.daily, reminders: 2),
    );

    final tomorrow = DateTime(2026, 9, 22, 7);
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime, sevenAm);
    expect(scheduler.active[reminder(alarm, 1)]?.dateTime,
        DateTime(2026, 9, 21, 7, 5));
    expect(scheduler.active[reminder(alarm, 2)]?.dateTime,
        DateTime(2026, 9, 21, 7, 10));
    expect(scheduler.active[followUpNativeId(alarm.id)]?.dateTime, tomorrow);
    expect(
      scheduler.active[reminder(alarm, 2, occurrence: tomorrow)]?.dateTime,
      DateTime(2026, 9, 22, 7, 10),
    );
    expect(scheduler.active[reminder(alarm, 3)], isNull);
  });

  test('without reminders only the occurrences are scheduled', () async {
    now = DateTime(2026, 9, 21, 6);
    final alarm = await service.save(
      _alarm(recurrence: AlarmScheduleType.daily, reminders: 0),
    );

    expect(scheduler.active.keys,
        {primaryNativeId(alarm.id), followUpNativeId(alarm.id)});
  });

  test('dismissing the first ring keeps the reminders', () async {
    final alarm = await ringingAlarm();
    expect(ringing.value?.upcomingReminders, [
      DateTime(2026, 9, 21, 7, 5),
      DateTime(2026, 9, 21, 7, 10),
    ]);

    await handler.dismiss(alarm, nativeId: primaryNativeId(alarm.id));

    expect(await scheduler.isRinging(primaryNativeId(alarm.id)), isFalse);
    expect(scheduler.active.containsKey(reminder(alarm, 1)), isTrue);
    expect(scheduler.active.containsKey(reminder(alarm, 2)), isTrue);
    // The regular schedule moves on to tomorrow.
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime,
        DateTime(2026, 9, 22, 7));
  });

  test('stopping the first ring from the notification keeps the reminders',
      () async {
    final alarm = await ringingAlarm();
    now = sevenAm.add(const Duration(seconds: 30));

    scheduler.stopFromNotification(primaryNativeId(alarm.id));
    await service.handleNativeUpdate(primaryNativeId(alarm.id));

    expect(scheduler.active.containsKey(reminder(alarm, 1)), isTrue);
    expect(scheduler.active.containsKey(reminder(alarm, 2)), isTrue);
  });

  test('each reminder ring counts down the remaining reminders', () async {
    final alarm = await ringingAlarm();
    await handler.dismiss(alarm, nativeId: primaryNativeId(alarm.id));

    await ringAt(reminder(alarm, 1), DateTime(2026, 9, 21, 7, 5));
    expect(ringing.value?.upcomingReminders, [DateTime(2026, 9, 21, 7, 10)]);
    final run = (await reincarnationRepository.activeForAlarm(alarm.id))
        .firstWhere((run) => run.originOccurrenceAt == sevenAm);
    expect(run.remainingCount, 1);

    await handler.dismiss(alarm, nativeId: reminder(alarm, 1));
    await ringAt(reminder(alarm, 2), DateTime(2026, 9, 21, 7, 10));
    expect(ringing.value?.upcomingReminders, isEmpty);
  });

  test('turning off reminders cancels today but keeps tomorrow', () async {
    final alarm = await ringingAlarm();

    await handler.dismissAll(alarm, nativeId: primaryNativeId(alarm.id));

    final tomorrow = DateTime(2026, 9, 22, 7);
    expect(scheduler.active.containsKey(reminder(alarm, 1)), isFalse);
    expect(scheduler.active.containsKey(reminder(alarm, 2)), isFalse);
    expect(scheduler.active[primaryNativeId(alarm.id)]?.dateTime, tomorrow);
    expect(
      scheduler.active.containsKey(reminder(alarm, 1, occurrence: tomorrow)),
      isTrue,
    );
    expect(ringing.value, isNull);
  });

  test('snooze rings again later without touching the reminders', () async {
    final alarm = await ringingAlarm();

    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));

    expect(await scheduler.isRinging(primaryNativeId(alarm.id)), isFalse);
    expect(scheduler.active[snoozeNativeId(alarm.id)]?.dateTime,
        sevenAm.add(const Duration(minutes: 10)));
    expect(scheduler.active.containsKey(reminder(alarm, 1)), isTrue);
    expect(ringing.value, isNull);
  });

  test('a one-time alarm is deleted only after its last reminder', () async {
    final alarm = await ringingAlarm(
      type: AlarmScheduleType.once,
      deleteAfterUse: true,
    );

    await handler.dismiss(alarm, nativeId: primaryNativeId(alarm.id));
    expect(await alarmRepository.findById(alarm.id), isNotNull);

    await ringAt(reminder(alarm, 1), DateTime(2026, 9, 21, 7, 5));
    await handler.dismiss(alarm, nativeId: reminder(alarm, 1));
    expect(await alarmRepository.findById(alarm.id), isNotNull);

    await ringAt(reminder(alarm, 2), DateTime(2026, 9, 21, 7, 10));
    await handler.dismiss(alarm, nativeId: reminder(alarm, 2));
    expect(await alarmRepository.findById(alarm.id), isNull);
    expect(scheduler.active, isEmpty);
  });

  test('delete-after-use removes a one-time alarm only on dismissal', () async {
    final alarm = await ringingAlarm(
      type: AlarmScheduleType.once,
      deleteAfterUse: true,
      reminders: 0,
    );

    await handler.snooze(alarm, nativeId: primaryNativeId(alarm.id));
    expect(await alarmRepository.findById(alarm.id), isNotNull);

    await ringAt(snoozeNativeId(alarm.id), DateTime(2026, 9, 21, 7, 10));
    await handler.dismiss(alarm, nativeId: snoozeNativeId(alarm.id));

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

  test('snoozing the test alarm sets it again after the delay', () async {
    handler.start();
    scheduler.ring(testAlarmNativeId);
    await _settle();
    expect(ringing.value?.canSnooze, isTrue);

    await handler.snoozeStandalone(
      ringing.value!,
      after: const Duration(minutes: 1),
      ringtone: 'gentle',
    );

    expect(await scheduler.isRinging(testAlarmNativeId), isFalse);
    final request = scheduler.active[testAlarmNativeId]!;
    expect(request.ringtone, 'gentle');
    expect(
      request.dateTime.difference(DateTime.now()).inSeconds,
      inInclusiveRange(55, 60),
    );
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
  int reminders = 2,
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
    reincarnationCount: reminders,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
