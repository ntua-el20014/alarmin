import 'alarm_model.dart';
import 'ringtone.dart';

enum TimePickerStyle { materialClock, cupertinoWheel }

/// Stored by index: keep `dark` first, it is the default.
enum AppThemeMode { dark, light }

class AppSettings {
  const AppSettings({
    required this.timePickerStyle,
    required this.isGroupedView,
    required this.defaultRingtone,
    required this.defaultVibration,
    required this.defaultSnoozeDuration,
    this.themeMode = AppThemeMode.dark,
  });

  const AppSettings.defaults()
      : timePickerStyle = TimePickerStyle.materialClock,
        isGroupedView = false,
        defaultRingtone = Ringtone.fallbackId,
        defaultVibration = VibrationSetting.standard,
        defaultSnoozeDuration = const Duration(minutes: 10),
        themeMode = AppThemeMode.dark;

  final TimePickerStyle timePickerStyle;
  final bool isGroupedView;
  final String defaultRingtone;
  final VibrationSetting defaultVibration;
  final Duration defaultSnoozeDuration;
  final AppThemeMode themeMode;

  AppSettings copyWith({
    TimePickerStyle? timePickerStyle,
    bool? isGroupedView,
    String? defaultRingtone,
    VibrationSetting? defaultVibration,
    Duration? defaultSnoozeDuration,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      timePickerStyle: timePickerStyle ?? this.timePickerStyle,
      isGroupedView: isGroupedView ?? this.isGroupedView,
      defaultRingtone: defaultRingtone ?? this.defaultRingtone,
      defaultVibration: defaultVibration ?? this.defaultVibration,
      defaultSnoozeDuration:
          defaultSnoozeDuration ?? this.defaultSnoozeDuration,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
