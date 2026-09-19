import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/data/services/alarm_service.dart';

void main() {
  late db.AppDatabase database;
  late FakeAlarmScheduler scheduler;
  late AlarmService service;
  final now = DateTime(2026, 9, 21, 6);

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    scheduler = FakeAlarmScheduler();
    service = AlarmService(
      repository: AlarmRepository(database),
      scheduler: scheduler,
      now: () => now,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and schedules the next recurrence', () async {
    final alarm = _alarm();

    await service.save(alarm);

    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.$1.id, alarm.id);
    expect(scheduler.scheduled.single.$2, DateTime(2026, 9, 21, 7));
    expect(
        (await AlarmRepository(database).watchAlarms().first)
            .single
            .nextOccurrenceAt,
        DateTime(2026, 9, 21, 7));
  });

  test('disabling an alarm cancels native scheduling', () async {
    final alarm = _alarm();
    await service.save(alarm);

    await service.setEnabled(alarm, false);

    expect(scheduler.cancelled, contains(alarm.id));
    expect(scheduler.scheduled, hasLength(1));
    expect(
        (await AlarmRepository(database).watchAlarms().first).single.isEnabled,
        isFalse);
  });

  test('maps a stable valid native id from a domain id', () {
    expect(nativeAlarmId('alarm-1'), nativeAlarmId('alarm-1'));
    expect(nativeAlarmId('alarm-1'), isNot(0));
    expect(nativeAlarmId('alarm-1'), isNot(-1));
  });
}

AlarmModel _alarm() {
  final createdAt = DateTime(2026, 9, 20);
  return AlarmModel(
    id: 'alarm-1',
    title: 'Morning alarm',
    recurrence: const RecurrenceRule(
      scheduleType: AlarmScheduleType.daily,
      timeOfDay: 7 * 60,
    ),
    isEnabled: true,
    deleteAfterUse: false,
    ringtone: 'assets/audio/default.mp3',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class FakeAlarmScheduler implements AlarmScheduler {
  final scheduled = <(AlarmModel, DateTime)>[];
  final cancelled = <String>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(AlarmModel alarm, DateTime occurrence) async {
    scheduled.add((alarm, occurrence));
    return true;
  }

  @override
  Future<bool> cancel(String alarmId) async {
    cancelled.add(alarmId);
    return true;
  }
}
