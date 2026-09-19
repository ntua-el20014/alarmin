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
}
