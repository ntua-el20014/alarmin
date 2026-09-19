import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart' as db;
import '../data/models/alarm_model.dart';
import '../data/models/app_settings.dart';
import '../data/models/category_model.dart';
import '../data/models/stopwatch_models.dart' as domain;
import '../data/repositories/alarm_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/stopwatch_repository.dart';
import '../data/services/alarm_scheduler.dart';
import '../data/services/alarm_service.dart';

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

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService(
    repository: ref.watch(alarmRepositoryProvider),
    scheduler: ref.watch(alarmSchedulerProvider),
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
