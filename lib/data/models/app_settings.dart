import 'alarm_model.dart';

enum TimePickerStyle { materialClock, cupertinoWheel }

class AppSettings {
  const AppSettings({
    required this.timePickerStyle,
    required this.isGroupedView,
    required this.defaultRingtone,
    required this.defaultVibration,
    required this.defaultSnoozeDuration,
  });

  const AppSettings.defaults()
      : timePickerStyle = TimePickerStyle.materialClock,
        isGroupedView = false,
        defaultRingtone = 'default',
        defaultVibration = VibrationSetting.standard,
        defaultSnoozeDuration = const Duration(minutes: 10);

  final TimePickerStyle timePickerStyle;
  final bool isGroupedView;
  final String defaultRingtone;
  final VibrationSetting defaultVibration;
  final Duration defaultSnoozeDuration;

  AppSettings copyWith({
    TimePickerStyle? timePickerStyle,
    bool? isGroupedView,
    String? defaultRingtone,
    VibrationSetting? defaultVibration,
    Duration? defaultSnoozeDuration,
  }) {
    return AppSettings(
      timePickerStyle: timePickerStyle ?? this.timePickerStyle,
      isGroupedView: isGroupedView ?? this.isGroupedView,
      defaultRingtone: defaultRingtone ?? this.defaultRingtone,
      defaultVibration: defaultVibration ?? this.defaultVibration,
      defaultSnoozeDuration:
          defaultSnoozeDuration ?? this.defaultSnoozeDuration,
    );
  }
}
