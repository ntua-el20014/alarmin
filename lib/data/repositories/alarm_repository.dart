import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/alarm_model.dart';
import '../models/mission.dart';
import '../models/recurrence_rule.dart';

class AlarmRepository {
  AlarmRepository(this._database);

  final AppDatabase _database;

  Stream<List<AlarmModel>> watchAlarms() {
    return _orderedAlarms().watch().asyncMap(_withWeekdays);
  }

  Future<List<AlarmModel>> getAll() async {
    return _withWeekdays(await _orderedAlarms().get());
  }

  SimpleSelectStatement<$AlarmsTable, Alarm> _orderedAlarms() {
    return _database.select(_database.alarms)
      ..orderBy([
        (alarm) => OrderingTerm(expression: alarm.nextOccurrenceAt),
      ]);
  }

  Future<List<AlarmModel>> _withWeekdays(List<Alarm> rows) async {
    final weekdayRows = await _database.select(_database.alarmWeekdays).get();
    final weekdaysByAlarm = <String, Set<int>>{};
    for (final row in weekdayRows) {
      weekdaysByAlarm.putIfAbsent(row.alarmId, () => <int>{}).add(row.weekday);
    }
    return [
      for (final row in rows)
        _toModel(row, weekdaysByAlarm[row.id] ?? const <int>{}),
    ];
  }

  Future<AlarmModel?> findById(String alarmId) async {
    final row = await (_database.select(_database.alarms)
          ..where((alarm) => alarm.id.equals(alarmId)))
        .getSingleOrNull();
    if (row == null) return null;
    final weekdays = await (_database.select(_database.alarmWeekdays)
          ..where((weekday) => weekday.alarmId.equals(alarmId)))
        .get();
    return _toModel(row, weekdays.map((weekday) => weekday.weekday).toSet());
  }

  Future<void> save(AlarmModel alarm) {
    return _database.transaction(() async {
      // An upsert, not insertOrReplace: REPLACE deletes the row first, which
      // would cascade-delete the alarm's reincarnation runs.
      await _database
          .into(_database.alarms)
          .insertOnConflictUpdate(_toCompanion(alarm));
      await (_database.delete(_database.alarmWeekdays)
            ..where((weekday) => weekday.alarmId.equals(alarm.id)))
          .go();
      await _database.batch((batch) {
        batch.insertAll(
          _database.alarmWeekdays,
          alarm.recurrence.daysOfWeek
              .map(
                (weekday) => AlarmWeekdaysCompanion.insert(
                  alarmId: alarm.id,
                  weekday: weekday,
                ),
              )
              .toList(),
        );
      });
    });
  }

  Future<void> delete(String alarmId) {
    return (_database.delete(_database.alarms)
          ..where((alarm) => alarm.id.equals(alarmId)))
        .go();
  }

  Future<void> setEnabled(String alarmId, bool isEnabled) {
    return (_database.update(_database.alarms)
          ..where((alarm) => alarm.id.equals(alarmId)))
        .write(AlarmsCompanion(isEnabled: Value(isEnabled)));
  }

  AlarmModel _toModel(Alarm row, Set<int> weekdays) {
    return AlarmModel(
      id: row.id,
      title: row.title,
      categoryId: row.categoryId,
      recurrence: RecurrenceRule(
        scheduleType: AlarmScheduleType.values[row.scheduleType],
        timeOfDay: row.timeOfDay,
        scheduledDate: row.scheduledDate,
        daysOfWeek: weekdays,
        intervalDays: row.intervalDays,
        scheduleStartDate: row.scheduleStartDate,
        scheduleEndDate: row.scheduleEndDate,
      ),
      isEnabled: row.isEnabled,
      deleteAfterUse: row.deleteAfterUse,
      ringtone: row.ringtone,
      vibration: VibrationSetting.values[row.vibration],
      wakeStyle: WakeStyle.values[row.wakeStyle],
      mission: Mission(
        type: MissionType.values[row.missionType],
        difficulty: MathDifficulty.values[row.missionDifficulty],
        count: row.missionCount,
      ),
      snoozeDuration: Duration(seconds: row.snoozeDurationSeconds),
      reincarnationCount: row.reincarnationCount,
      reincarnationInterval:
          Duration(seconds: row.reincarnationIntervalSeconds),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      nextOccurrenceAt: row.nextOccurrenceAt,
      skippedOccurrenceAt: row.skippedOccurrenceAt,
    );
  }

  AlarmsCompanion _toCompanion(AlarmModel alarm) {
    final recurrence = alarm.recurrence;
    return AlarmsCompanion.insert(
      id: alarm.id,
      title: alarm.title,
      categoryId: Value(alarm.categoryId),
      scheduleType: recurrence.scheduleType.index,
      timeOfDay: recurrence.timeOfDay,
      scheduledDate: Value(recurrence.scheduledDate),
      intervalDays: Value(recurrence.intervalDays),
      scheduleStartDate: Value(recurrence.scheduleStartDate),
      scheduleEndDate: Value(recurrence.scheduleEndDate),
      isEnabled: alarm.isEnabled,
      deleteAfterUse: alarm.deleteAfterUse,
      ringtone: alarm.ringtone,
      vibration: alarm.vibration.index,
      wakeStyle: Value(alarm.wakeStyle.index),
      missionType: Value(alarm.mission.type.index),
      missionDifficulty: Value(alarm.mission.difficulty.index),
      missionCount: Value(alarm.mission.count),
      snoozeDurationSeconds: alarm.snoozeDuration.inSeconds,
      reincarnationCount: alarm.reincarnationCount,
      reincarnationIntervalSeconds: alarm.reincarnationInterval.inSeconds,
      createdAt: alarm.createdAt,
      updatedAt: alarm.updatedAt,
      nextOccurrenceAt: Value(alarm.nextOccurrenceAt),
      skippedOccurrenceAt: Value(alarm.skippedOccurrenceAt),
    );
  }
}
