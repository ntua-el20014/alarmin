import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/models/category_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/reincarnation_model.dart';
import 'package:alarmin/data/models/stopwatch_models.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/category_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
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

  test('seeds default categories and settings on first open', () async {
    final categoryRepository = CategoryRepository(database);
    final settingsRepository = SettingsRepository(database);

    final categories = await categoryRepository.watchCategories().first;
    final settings = await settingsRepository.load();

    expect(
        categories.map((category) => category.id),
        containsAll(<String>[
          'category-personal',
          'category-work',
          'category-health',
        ]));
    expect(settings.timePickerStyle, TimePickerStyle.materialClock);
    expect(settings.isGroupedView, isFalse);
  });

  test('saves and reloads an alarm with normalized weekdays', () async {
    final repository = AlarmRepository(database);
    await CategoryRepository(database).save(
      CategoryModel(
        id: 'work',
        name: 'Work',
        emoji: '💼',
        createdAt: now,
        updatedAt: now,
      ),
    );
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
    final categories = await categoryRepository.watchCategories().first;
    expect(categories.map((category) => category.id), isNot(contains('work')));
  });

  test('editing a category keeps its alarms in it', () async {
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

    await categoryRepository.save(
      CategoryModel(
        id: category.id,
        name: 'Office',
        emoji: '🏢',
        createdAt: category.createdAt,
        updatedAt: now,
      ),
    );

    expect((await alarmRepository.findById('alarm-1'))?.categoryId, 'work');
  });

  test('a category keeps its alarm defaults', () async {
    final categoryRepository = CategoryRepository(database);
    await categoryRepository.save(
      CategoryModel(
        id: 'meds',
        name: 'Meds',
        emoji: '💊',
        defaultRingtone: 'gentle',
        defaultVibration: VibrationSetting.off,
        defaultWakeStyle: WakeStyle.gentle,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await categoryRepository.save(
      CategoryModel(
        id: 'plain',
        name: 'Plain',
        emoji: '📌',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final meds = await categoryRepository.findById('meds');
    expect(meds?.defaultRingtone, 'gentle');
    expect(meds?.defaultVibration, VibrationSetting.off);
    expect(meds?.defaultWakeStyle, WakeStyle.gentle);
    final plain = await categoryRepository.findById('plain');
    expect(plain?.hasAlarmDefaults, isFalse);
  });

  test('an alarm and the settings keep their wake style', () async {
    final settings = SettingsRepository(database);
    await settings.save(
      (await settings.load()).copyWith(defaultWakeStyle: WakeStyle.gentle),
    );
    expect((await settings.load()).defaultWakeStyle, WakeStyle.gentle);

    final alarms = AlarmRepository(database);
    await alarms.save(
      AlarmModel(
        id: 'gentle-alarm',
        title: 'Gentle',
        recurrence: const RecurrenceRule(
          scheduleType: AlarmScheduleType.daily,
          timeOfDay: 420,
        ),
        isEnabled: true,
        deleteAfterUse: false,
        ringtone: 'classic',
        vibration: VibrationSetting.standard,
        wakeStyle: WakeStyle.gentle,
        snoozeDuration: const Duration(minutes: 5),
        reincarnationCount: 0,
        reincarnationInterval: const Duration(minutes: 5),
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(
        (await alarms.findById('gentle-alarm'))?.wakeStyle, WakeStyle.gentle);
  });

  test('re-saving an alarm keeps its pending reminders', () async {
    final alarmRepository = AlarmRepository(database);
    final reincarnationRepository = ReincarnationRepository(database);
    final alarm = _alarm();
    await alarmRepository.save(alarm);
    await reincarnationRepository.save(
      ReincarnationRunModel.forOccurrence(
        alarmId: alarm.id,
        occurrence: now,
        reminderCount: 2,
        interval: const Duration(minutes: 5),
      ),
    );

    await alarmRepository.save(alarm.copyWith(title: 'Renamed'));

    expect(
      await reincarnationRepository.activeForAlarm(alarm.id),
      hasLength(1),
    );
  });

  test('deleting an alarm deletes its weekdays and snooze chains', () async {
    final alarmRepository = AlarmRepository(database);
    final alarm = _alarm();
    await alarmRepository.save(alarm);

    await alarmRepository.delete(alarm.id);

    expect(await database.select(database.alarmWeekdays).get(), isEmpty);
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
        timerRingtone: 'digital',
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
    expect((await settingsRepository.load()).timerRingtone, 'digital');
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
