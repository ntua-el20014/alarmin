import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/alarm_model.dart';
import '../models/recurrence_rule.dart';

class AlarmRepository {
  AlarmRepository(this._database);

  final AppDatabase _database;

  Stream<List<AlarmModel>> watchAlarms() {
    final query = _database.select(_database.alarms)
      ..orderBy([
        (alarm) => OrderingTerm(expression: alarm.nextOccurrenceAt),
      ]);

    return query.watch().asyncMap((rows) async {
      final alarms = <AlarmModel>[];
      for (final row in rows) {
        final weekdays = await (_database.select(_database.alarmWeekdays)
              ..where((weekday) => weekday.alarmId.equals(row.id)))
            .get();
        alarms.add(
            _toModel(row, weekdays.map((weekday) => weekday.weekday).toSet()));
      }
      return alarms;
    });
  }

  Future<void> save(AlarmModel alarm) {
    return _database.transaction(() async {
      await _database.into(_database.alarms).insert(
            _toCompanion(alarm),
            mode: InsertMode.insertOrReplace,
          );
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
      snoozeDuration: Duration(seconds: row.snoozeDurationSeconds),
      reincarnationCount: row.reincarnationCount,
      reincarnationInterval:
          Duration(seconds: row.reincarnationIntervalSeconds),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      nextOccurrenceAt: row.nextOccurrenceAt,
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
      snoozeDurationSeconds: alarm.snoozeDuration.inSeconds,
      reincarnationCount: alarm.reincarnationCount,
      reincarnationIntervalSeconds: alarm.reincarnationInterval.inSeconds,
      createdAt: alarm.createdAt,
      updatedAt: alarm.updatedAt,
      nextOccurrenceAt: Value(alarm.nextOccurrenceAt),
    );
  }
}
