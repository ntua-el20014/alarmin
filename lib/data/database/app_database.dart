import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Alarms extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get scheduleType => integer()();
  IntColumn get timeOfDay => integer()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  IntColumn get intervalDays => integer().nullable()();
  DateTimeColumn get scheduleStartDate => dateTime().nullable()();
  DateTimeColumn get scheduleEndDate => dateTime().nullable()();
  BoolColumn get isEnabled => boolean()();
  BoolColumn get deleteAfterUse => boolean()();
  TextColumn get ringtone => text()();
  IntColumn get vibration => integer()();
  IntColumn get snoozeDurationSeconds => integer()();
  IntColumn get reincarnationCount => integer()();
  IntColumn get reincarnationIntervalSeconds => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get nextOccurrenceAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AlarmWeekdays extends Table {
  TextColumn get alarmId =>
      text().references(Alarms, #id, onDelete: KeyAction.cascade)();
  IntColumn get weekday => integer()();

  @override
  Set<Column<Object>> get primaryKey => {alarmId, weekday};
}

class ReincarnationRuns extends Table {
  TextColumn get id => text()();
  TextColumn get alarmId =>
      text().references(Alarms, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get originOccurrenceAt => dateTime()();
  IntColumn get remainingCount => integer()();
  DateTimeColumn get nextFireAt => dateTime()();
  IntColumn get status => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StopwatchSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get totalTimeMs => integer()();
  IntColumn get status => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StopwatchLaps extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(StopwatchSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer()();
  IntColumn get elapsedAtLapMs => integer()();
  IntColumn get lapDurationMs => integer()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get timePickerStyle => integer()();
  BoolColumn get isGroupedView => boolean()();
  TextColumn get defaultRingtone => text()();
  IntColumn get defaultVibration => integer()();
  IntColumn get defaultSnoozeDurationSeconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Categories,
    Alarms,
    AlarmWeekdays,
    ReincarnationRuns,
    StopwatchSessions,
    StopwatchLaps,
    AppSettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'alarmin'));

  @override
  int get schemaVersion => 1;
}
