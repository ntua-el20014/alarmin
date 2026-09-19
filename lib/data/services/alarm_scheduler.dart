import 'package:alarm/alarm.dart' as native_alarm;

import '../models/alarm_model.dart';

abstract interface class AlarmScheduler {
  bool get isSupported;
  Stream<int> get ringEvents;
  Future<void> initialize();
  Future<bool> schedule(AlarmModel alarm, DateTime occurrence);
  Future<bool> cancel(String alarmId);
}

class NativeAlarmScheduler implements AlarmScheduler {
  @override
  bool get isSupported => native_alarm.Alarm.android || native_alarm.Alarm.iOS;

  @override
  Stream<int> get ringEvents =>
      native_alarm.Alarm.ringStream.stream.map((settings) => settings.id);

  @override
  Future<void> initialize() async {
    if (isSupported) {
      await native_alarm.Alarm.init(showDebugLogs: false);
    }
  }

  @override
  Future<bool> schedule(AlarmModel alarm, DateTime occurrence) {
    if (!isSupported) {
      return Future.value(false);
    }
    return native_alarm.Alarm.set(
      alarmSettings: native_alarm.AlarmSettings(
        id: nativeAlarmId(alarm.id),
        dateTime: occurrence,
        assetAudioPath: alarm.ringtone,
        notificationSettings: native_alarm.NotificationSettings(
          title: alarm.title,
          body: 'Alarm',
          stopButton: 'Dismiss',
        ),
        vibrate: alarm.vibration != VibrationSetting.off,
      ),
    );
  }

  @override
  Future<bool> cancel(String alarmId) {
    if (!isSupported) {
      return Future.value(true);
    }
    return native_alarm.Alarm.stop(nativeAlarmId(alarmId));
  }
}

int nativeAlarmId(String alarmId) {
  var hash = 2166136261;
  for (final codeUnit in alarmId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  if (hash == 0 || hash == 0x7fffffff) {
    return 1;
  }
  return hash;
}
