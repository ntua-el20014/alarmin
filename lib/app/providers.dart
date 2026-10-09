import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' as db;
import '../data/models/alarm_model.dart';
import '../data/models/app_settings.dart';
import '../data/models/category_model.dart';
import '../data/models/ringing_alarm.dart';
import '../data/models/ringtone.dart';
import '../data/models/stopwatch_models.dart' as domain;
import '../data/repositories/alarm_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/stopwatch_repository.dart';
import '../data/repositories/reincarnation_repository.dart';
import '../data/services/alarm_permissions.dart';
import '../data/services/alarm_scheduler.dart';
import '../data/services/alarm_ring_handler.dart';
import '../data/services/alarm_service.dart';
import '../data/services/calendar_occurrence_service.dart';
import '../features/timer/timer_completion_service.dart';

final databaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final stopwatchRepositoryProvider = Provider<StopwatchRepository>((ref) {
  return StopwatchRepository(ref.watch(databaseProvider));
});

final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) {
  return NativeAlarmScheduler();
});

final reincarnationRepositoryProvider =
    Provider<ReincarnationRepository>((ref) {
  return ReincarnationRepository(ref.watch(databaseProvider));
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService(
    repository: ref.watch(alarmRepositoryProvider),
    reincarnationRepository: ref.watch(reincarnationRepositoryProvider),
    scheduler: ref.watch(alarmSchedulerProvider),
  );
});

/// The alarm currently ringing, or null. Drives the ring screen.
final ringingAlarmProvider = Provider<ValueNotifier<RingingAlarm?>>((ref) {
  final ringing = ValueNotifier<RingingAlarm?>(null);
  ref.onDispose(ringing.dispose);
  return ringing;
});

final alarmRingHandlerProvider = Provider<AlarmRingHandler>((ref) {
  final handler = AlarmRingHandler(
    alarmService: ref.watch(alarmServiceProvider),
    scheduler: ref.watch(alarmSchedulerProvider),
    ringing: ref.watch(ringingAlarmProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

final alarmPermissionsProvider = Provider<AlarmPermissions>((ref) {
  return AlarmPermissions();
});

final calendarOccurrenceServiceProvider =
    Provider<CalendarOccurrenceService>((ref) {
  return CalendarOccurrenceService();
});

final timerCompletionProvider = Provider<TimerCompletionNotifier>((ref) {
  return NativeTimerCompletionNotifier(
    ref.watch(alarmSchedulerProvider),
    () =>
        ref.read(settingsProvider).value?.defaultRingtone ??
        Ringtone.fallbackId,
  );
});

final alarmsProvider = StreamProvider<List<AlarmModel>>((ref) {
  return ref.watch(alarmRepositoryProvider).watchAlarms();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final stopwatchHistoryProvider =
    StreamProvider<List<domain.StopwatchSession>>((ref) {
  return ref.watch(stopwatchRepositoryProvider).watchHistory();
});
