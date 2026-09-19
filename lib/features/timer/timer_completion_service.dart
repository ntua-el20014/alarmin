import 'package:alarm/alarm.dart' as native_alarm;

abstract interface class TimerCompletionNotifier {
  Future<void> notify();
}

class NativeTimerCompletionNotifier implements TimerCompletionNotifier {
  static const _completionId = 2147483646;

  @override
  Future<void> notify() async {
    if (!native_alarm.Alarm.android && !native_alarm.Alarm.iOS) return;
    await native_alarm.Alarm.set(
      alarmSettings: native_alarm.AlarmSettings(
        id: _completionId,
        dateTime: DateTime.now().add(const Duration(seconds: 1)),
        assetAudioPath: 'packages/alarm/assets/not_blank.mp3',
        loopAudio: false,
        vibrate: true,
        notificationSettings: const native_alarm.NotificationSettings(
          title: 'Timer complete',
          body: 'Your timer has finished.',
        ),
      ),
    );
  }
}
