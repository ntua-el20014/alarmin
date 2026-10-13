import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/alarm_model.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  Future<AppSettings> load() async {
    final row = await (_database.select(_database.appSettingsTable)
          ..where((settings) => settings.id.equals(1)))
        .getSingleOrNull();
    if (row == null) {
      const defaults = AppSettings.defaults();
      await _database
          .into(_database.appSettingsTable)
          .insert(_toCompanion(defaults));
      return defaults;
    }
    return _toModel(row);
  }

  Stream<AppSettings> watch() async* {
    yield await load();
    await for (final rows
        in _database.select(_database.appSettingsTable).watch()) {
      if (rows.isNotEmpty) {
        yield _toModel(rows.first);
      }
    }
  }

  Future<void> save(AppSettings settings) {
    return _database.into(_database.appSettingsTable).insert(
          _toCompanion(settings),
          mode: InsertMode.insertOrReplace,
        );
  }

  static AppSettings _toModel(AppSettingsTableData row) {
    return AppSettings(
      timePickerStyle: TimePickerStyle.values[row.timePickerStyle],
      isGroupedView: row.isGroupedView,
      defaultRingtone: row.defaultRingtone,
      defaultVibration: VibrationSetting.values[row.defaultVibration],
      defaultSnoozeDuration:
          Duration(seconds: row.defaultSnoozeDurationSeconds),
      themeMode: AppThemeMode.values[row.themeMode],
      timerRingtone: row.timerRingtone,
      upcomingAlarmNotice: row.upcomingAlarmNotice,
    );
  }

  static AppSettingsTableCompanion _toCompanion(AppSettings settings) {
    return AppSettingsTableCompanion.insert(
      id: const Value(1),
      timePickerStyle: settings.timePickerStyle.index,
      isGroupedView: settings.isGroupedView,
      defaultRingtone: settings.defaultRingtone,
      defaultVibration: settings.defaultVibration.index,
      defaultSnoozeDurationSeconds: settings.defaultSnoozeDuration.inSeconds,
      themeMode: Value(settings.themeMode.index),
      timerRingtone: Value(settings.timerRingtone),
      upcomingAlarmNotice: Value(settings.upcomingAlarmNotice),
    );
  }
}
