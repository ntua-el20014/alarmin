import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';

/// The schema v1 databases were actually created with: no foreign keys and
/// no reincarnation chain columns.
const _v1Schema = [
  'CREATE TABLE categories (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, '
      'emoji TEXT NOT NULL, created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
  'CREATE TABLE alarms (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, '
      'category_id TEXT NULL, schedule_type INTEGER NOT NULL, '
      'time_of_day INTEGER NOT NULL, scheduled_date INTEGER NULL, '
      'interval_days INTEGER NULL, schedule_start_date INTEGER NULL, '
      'schedule_end_date INTEGER NULL, is_enabled INTEGER NOT NULL, '
      'delete_after_use INTEGER NOT NULL, ringtone TEXT NOT NULL, '
      'vibration INTEGER NOT NULL, snooze_duration_seconds INTEGER NOT NULL, '
      'reincarnation_count INTEGER NOT NULL, '
      'reincarnation_interval_seconds INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
      'next_occurrence_at INTEGER NULL)',
  'CREATE TABLE alarm_weekdays (alarm_id TEXT NOT NULL, '
      'weekday INTEGER NOT NULL, PRIMARY KEY (alarm_id, weekday))',
  'CREATE TABLE reincarnation_runs (id TEXT NOT NULL PRIMARY KEY, '
      'alarm_id TEXT NOT NULL, origin_occurrence_at INTEGER NOT NULL, '
      'remaining_count INTEGER NOT NULL, next_fire_at INTEGER NOT NULL, '
      'status INTEGER NOT NULL)',
  'CREATE TABLE stopwatch_sessions (id TEXT NOT NULL PRIMARY KEY, '
      'started_at INTEGER NOT NULL, ended_at INTEGER NULL, '
      'total_time_ms INTEGER NOT NULL, status INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL)',
  'CREATE TABLE stopwatch_laps (id TEXT NOT NULL PRIMARY KEY, '
      'session_id TEXT NOT NULL, sequence INTEGER NOT NULL, '
      'elapsed_at_lap_ms INTEGER NOT NULL, lap_duration_ms INTEGER NOT NULL, '
      'recorded_at INTEGER NOT NULL)',
  'CREATE TABLE app_settings_table (id INTEGER NOT NULL DEFAULT 1 '
      'PRIMARY KEY, time_picker_style INTEGER NOT NULL, '
      'is_grouped_view INTEGER NOT NULL, default_ringtone TEXT NOT NULL, '
      'default_vibration INTEGER NOT NULL, '
      'default_snooze_duration_seconds INTEGER NOT NULL)',
  "INSERT INTO categories VALUES ('work', 'Work', '💼', 0, 0)",
  "INSERT INTO alarms VALUES ('alarm-1', 'Morning', 'work', 2, 420, NULL, "
      "NULL, NULL, NULL, 1, 0, 'assets/audio/default.mp3', 1, 600, 2, 300, "
      '0, 0, NULL)',
  "INSERT INTO alarm_weekdays VALUES ('alarm-1', 1), ('gone', 3)",
  "INSERT INTO reincarnation_runs VALUES ('run-1', 'alarm-1', 0, 1, 0, 0)",
  'PRAGMA user_version = 1',
];

void main() {
  test('upgrades a v1 database and restores its foreign keys', () async {
    final database = db.AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final statement in _v1Schema) {
            raw.execute(statement);
          }
        },
      ),
    );
    addTearDown(database.close);

    final alarms = await AlarmRepository(database).getAll();
    expect(alarms.single.title, 'Morning');
    expect(alarms.single.categoryId, 'work');
    expect(alarms.single.recurrence.daysOfWeek, {1});

    // The orphaned weekday row is gone.
    expect(await database.select(database.alarmWeekdays).get(), hasLength(1));
    // Legacy runs have no chain timing and are ignored.
    expect(
      await ReincarnationRepository(database).activeForAlarm('alarm-1'),
      isEmpty,
    );

    // Cascades now work.
    await AlarmRepository(database).delete('alarm-1');
    expect(await database.select(database.alarmWeekdays).get(), isEmpty);
    expect(await database.select(database.reincarnationRuns).get(), isEmpty);

    final version =
        await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), database.schemaVersion);
  });
}
