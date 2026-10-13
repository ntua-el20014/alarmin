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
    this.timerRingtone,
    this.upcomingAlarmNotice = true,
    this.defaultWakeStyle = WakeStyle.normal,
  });

  const AppSettings.defaults()
      : timePickerStyle = TimePickerStyle.materialClock,
        isGroupedView = false,
        defaultRingtone = Ringtone.fallbackId,
        defaultVibration = VibrationSetting.standard,
        defaultSnoozeDuration = const Duration(minutes: 10),
        themeMode = AppThemeMode.dark,
        timerRingtone = null,
        upcomingAlarmNotice = true,
        defaultWakeStyle = WakeStyle.normal;

  final TimePickerStyle timePickerStyle;
  final bool isGroupedView;
  final String defaultRingtone;
  final VibrationSetting defaultVibration;
  final Duration defaultSnoozeDuration;
  final AppThemeMode themeMode;

  /// Sound for the timer; null means [defaultRingtone].
  final String? timerRingtone;

  /// Quiet notification an hour before each alarm, with a Skip button.
  final bool upcomingAlarmNotice;

  /// Wake style of new alarms, unless their category sets one.
  final WakeStyle defaultWakeStyle;

  String get effectiveTimerRingtone => timerRingtone ?? defaultRingtone;

  AppSettings copyWith({
    TimePickerStyle? timePickerStyle,
    bool? isGroupedView,
    String? defaultRingtone,
    VibrationSetting? defaultVibration,
    Duration? defaultSnoozeDuration,
    AppThemeMode? themeMode,
    String? timerRingtone,
    bool clearTimerRingtone = false,
    bool? upcomingAlarmNotice,
    WakeStyle? defaultWakeStyle,
  }) {
    return AppSettings(
      timePickerStyle: timePickerStyle ?? this.timePickerStyle,
      isGroupedView: isGroupedView ?? this.isGroupedView,
      defaultRingtone: defaultRingtone ?? this.defaultRingtone,
      defaultVibration: defaultVibration ?? this.defaultVibration,
      defaultSnoozeDuration:
          defaultSnoozeDuration ?? this.defaultSnoozeDuration,
      themeMode: themeMode ?? this.themeMode,
      timerRingtone:
          clearTimerRingtone ? null : timerRingtone ?? this.timerRingtone,
      upcomingAlarmNotice: upcomingAlarmNotice ?? this.upcomingAlarmNotice,
      defaultWakeStyle: defaultWakeStyle ?? this.defaultWakeStyle,
    );
  }
}
