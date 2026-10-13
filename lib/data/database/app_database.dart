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
  // Added in schema v6; an occurrence skipped from the upcoming alarm
  // notification, so rescheduling moves past it.
  DateTimeColumn get skippedOccurrenceAt => dateTime().nullable()();

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
  // Added in schema v2: the reminder count and interval of the run, and the
  // first reminder's time. Null on legacy rows, which are ignored.
  DateTimeColumn get firstFireAt => dateTime().nullable()();
  IntColumn get chainReincarnationCount => integer().nullable()();
  IntColumn get chainIntervalSeconds => integer().nullable()();

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
  // Added in schema v4; AppThemeMode index, 0 = dark.
  IntColumn get themeMode => integer().withDefault(const Constant(0))();
  // Added in schema v5; null means "same as defaultRingtone".
  TextColumn get timerRingtone => text().nullable()();
  // Added in schema v6; quiet notification an hour before each alarm.
  BoolColumn get upcomingAlarmNotice =>
      boolean().withDefault(const Constant(true))();

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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _seedDefaults();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            // v1 tables were generated without their foreign keys (drift_dev
            // could not resolve the referenced classes), so rows were left
            // behind by deletes. Drop the orphans, then rebuild the tables
            // with their constraints. Foreign keys are still off here.
            await customStatement(
              'DELETE FROM alarm_weekdays '
              'WHERE alarm_id NOT IN (SELECT id FROM alarms)',
            );
            await customStatement(
              'DELETE FROM reincarnation_runs '
              'WHERE alarm_id NOT IN (SELECT id FROM alarms)',
            );
            await customStatement(
              'DELETE FROM stopwatch_laps '
              'WHERE session_id NOT IN (SELECT id FROM stopwatch_sessions)',
            );
            await customStatement(
              'UPDATE alarms SET category_id = NULL '
              'WHERE category_id NOT IN (SELECT id FROM categories)',
            );
            await migrator.alterTable(
              TableMigration(
                alarms,
                newColumns: [alarms.skippedOccurrenceAt],
              ),
            );
            await migrator.alterTable(TableMigration(alarmWeekdays));
            await migrator.alterTable(
              TableMigration(
                reincarnationRuns,
                newColumns: [
                  reincarnationRuns.firstFireAt,
                  reincarnationRuns.chainReincarnationCount,
                  reincarnationRuns.chainIntervalSeconds,
                ],
              ),
            );
            await migrator.alterTable(TableMigration(stopwatchLaps));
          }
          if (from < 3) {
            // Runs used to be snooze chains; they now hold the reminders of
            // one occurrence. They are runtime state and get recreated.
            await delete(reincarnationRuns).go();
          }
          if (from < 4) {
            await migrator.addColumn(
                appSettingsTable, appSettingsTable.themeMode);
          }
          if (from < 5) {
            await migrator.addColumn(
                appSettingsTable, appSettingsTable.timerRingtone);
          }
          if (from < 6) {
            // Rebuilt with the column above when coming from v1.
            if (from >= 2) {
              await migrator.addColumn(alarms, alarms.skippedOccurrenceAt);
            }
            await migrator.addColumn(
                appSettingsTable, appSettingsTable.upcomingAlarmNotice);
          }
        },
        beforeOpen: (details) async {
          // SQLite ignores the declared cascade/set-null actions unless
          // foreign keys are enabled on every connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
          id: 'category-personal',
          name: 'Personal',
          emoji: '🏠',
          createdAt: now,
          updatedAt: now,
        ),
        CategoriesCompanion.insert(
          id: 'category-work',
          name: 'Work',
          emoji: '💼',
          createdAt: now,
          updatedAt: now,
        ),
        CategoriesCompanion.insert(
          id: 'category-health',
          name: 'Health',
          emoji: '❤️',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    });
    await into(appSettingsTable).insert(
      const AppSettingsTableCompanion(
        id: Value(1),
        timePickerStyle: Value(0),
        isGroupedView: Value(false),
        defaultRingtone: Value('classic'),
        defaultVibration: Value(1),
        defaultSnoozeDurationSeconds: Value(600),
      ),
    );
  }
}
