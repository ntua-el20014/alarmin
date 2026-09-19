import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
import 'package:alarmin/data/services/alarm_ring_handler.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/data/services/alarm_service.dart';

void main() {
  late db.AppDatabase database;
  late FakeScheduler scheduler;
  late AlarmRepository alarmRepository;
  late AlarmRingHandler handler;
  final now = DateTime(2026, 9, 21, 7);

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    scheduler = FakeScheduler();
    alarmRepository = AlarmRepository(database);
    final service = AlarmService(
      repository: alarmRepository,
      scheduler: scheduler,
      now: () => now,
    );
    handler = AlarmRingHandler(
      alarmRepository: alarmRepository,
      reincarnationRepository: ReincarnationRepository(database),
      alarmService: service,
      scheduler: scheduler,
      now: () => now,
    );
  });

  tearDown(() async {
    await handler.dispose();
    await database.close();
    await scheduler.events.close();
  });

  test('first snooze creates one fixed reincarnation chain', () async {
    final alarm = _alarm(recurrence: AlarmScheduleType.daily);
    await alarmRepository.save(alarm);

    await handler.snooze(alarm);

    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.$2, now.add(alarm.snoozeDuration));
    final run = await ReincarnationRepository(database).findActive(alarm.id);
    expect(run?.remainingCount, alarm.reincarnationCount);
  });

  test('active reincarnation advances by its interval after a ring', () async {
    final alarm = _alarm(recurrence: AlarmScheduleType.daily);
    await alarmRepository.save(alarm);
    await handler.snooze(alarm);

    final run = await ReincarnationRepository(database).findActive(alarm.id);
    await handler.handleNativeRing(nativeAlarmId(alarm.id));

    expect(scheduler.scheduled, hasLength(2));
    expect(scheduler.scheduled.last.$2, now.add(alarm.reincarnationInterval));
    expect(
      (await ReincarnationRepository(database).findActive(alarm.id))
          ?.remainingCount,
      run!.remainingCount - 1,
    );
  });

  test('delete-after-use removes a one-time alarm only on dismissal', () async {
    final alarm =
        _alarm(recurrence: AlarmScheduleType.once, deleteAfterUse: true);
    await alarmRepository.save(alarm);

    await handler.snooze(alarm);
    expect(await alarmRepository.findById(alarm.id), isNotNull);

    await handler.dismiss(alarm);

    expect(await alarmRepository.findById(alarm.id), isNull);
  });
}

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
    ringtone: 'assets/audio/default.mp3',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
    nextOccurrenceAt: DateTime(2026, 9, 21, 7),
  );
}

class FakeScheduler implements AlarmScheduler {
  final events = StreamController<int>.broadcast();
  final scheduled = <(AlarmModel, DateTime)>[];

  @override
  bool get isSupported => true;

  @override
  Stream<int> get ringEvents => events.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(AlarmModel alarm, DateTime occurrence) async {
    scheduled.add((alarm, occurrence));
    return true;
  }

  @override
  Future<bool> cancel(String alarmId) async => true;
}
