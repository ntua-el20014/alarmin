import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/models/category_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/stopwatch_models.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/category_repository.dart';
import 'package:alarmin/data/repositories/settings_repository.dart';
import 'package:alarmin/data/repositories/stopwatch_repository.dart';

void main() {
  late db.AppDatabase database;
  late DateTime now;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 9, 21, 10);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves and reloads an alarm with normalized weekdays', () async {
    final repository = AlarmRepository(database);
    final alarm = _alarm(categoryId: 'work');

    await repository.save(alarm);
    final loaded = await repository.watchAlarms().first;

    expect(loaded, hasLength(1));
    expect(loaded.single.id, alarm.id);
    expect(loaded.single.categoryId, 'work');
    expect(loaded.single.recurrence.daysOfWeek,
        <int>{DateTime.monday, DateTime.friday});
    expect(loaded.single.recurrence.scheduleType, AlarmScheduleType.weekly);
  });

  test('deleting a category leaves its alarms uncategorized', () async {
    final categoryRepository = CategoryRepository(database);
    final alarmRepository = AlarmRepository(database);
    final category = CategoryModel(
      id: 'work',
      name: 'Work',
      emoji: '💼',
      createdAt: now,
      updatedAt: now,
    );

    await categoryRepository.save(category);
    await alarmRepository.save(_alarm(categoryId: category.id));
    await categoryRepository.delete(category.id);

    final loaded = await alarmRepository.watchAlarms().first;
    expect(loaded.single.categoryId, isNull);
    expect(await categoryRepository.watchCategories().first, isEmpty);
  });

  test('persists settings and completed stopwatch history', () async {
    final settingsRepository = SettingsRepository(database);
    final stopwatchRepository = StopwatchRepository(database);
    final settings = await settingsRepository.load();
    final session = StopwatchSession(
      id: 'session-1',
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 2)),
      totalTimeMs: 120000,
      status: StopwatchSessionStatus.completed,
      createdAt: now,
    );

    await settingsRepository.save(
      AppSettings(
        timePickerStyle: TimePickerStyle.cupertinoWheel,
        isGroupedView: true,
        defaultRingtone: settings.defaultRingtone,
        defaultVibration: settings.defaultVibration,
        defaultSnoozeDuration: settings.defaultSnoozeDuration,
      ),
    );
    await stopwatchRepository.saveCompletedSession(session, [
      StopwatchLap(
        id: 'lap-1',
        sessionId: session.id,
        sequence: 1,
        elapsedAtLapMs: 60000,
        lapDurationMs: 60000,
        recordedAt: now.add(const Duration(minutes: 1)),
      ),
    ]);

    expect((await settingsRepository.load()).timePickerStyle,
        TimePickerStyle.cupertinoWheel);
    expect(
        (await stopwatchRepository.watchHistory().first).single.id, session.id);
  });
}

AlarmModel _alarm({String? categoryId}) {
  final now = DateTime(2026, 9, 21, 10);
  return AlarmModel(
    id: 'alarm-1',
    title: 'Morning alarm',
    categoryId: categoryId,
    recurrence: RecurrenceRule(
      scheduleType: AlarmScheduleType.weekly,
      timeOfDay: 7 * 60,
      daysOfWeek: <int>{DateTime.monday, DateTime.friday},
    ),
    isEnabled: true,
    deleteAfterUse: false,
    ringtone: 'default',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: now,
    updatedAt: now,
    nextOccurrenceAt: DateTime(2026, 9, 25, 7),
  );
}
