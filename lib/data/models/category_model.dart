import 'alarm_model.dart';
import 'mission.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
    this.defaultRingtone,
    this.defaultVibration,
    this.defaultWakeStyle,
    this.defaultMission,
  });

  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Defaults for new alarms in this category; null means the app-wide
  /// default from Settings.
  final String? defaultRingtone;
  final VibrationSetting? defaultVibration;
  final WakeStyle? defaultWakeStyle;

  /// Null means no mission.
  final Mission? defaultMission;

  bool get hasAlarmDefaults =>
      defaultRingtone != null ||
      defaultVibration != null ||
      defaultWakeStyle != null ||
      defaultMission != null;
}
