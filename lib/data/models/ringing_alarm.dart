import '../services/alarm_scheduler.dart';
import 'alarm_model.dart';

/// A native alarm that is currently ringing, as shown by the ring screen.
class RingingAlarm {
  const RingingAlarm({
    required this.nativeId,
    required this.title,
    this.alarm,
    this.canSnooze = false,
  });

  /// A ringing alarm that does not belong to a saved [AlarmModel], such as
  /// the timer or the settings test alarm.
  factory RingingAlarm.standalone(int nativeId) {
    return RingingAlarm(
      nativeId: nativeId,
      title: switch (nativeId) {
        timerNativeId => 'Timer finished',
        testAlarmNativeId => 'Test alarm',
        _ => 'Alarm',
      },
    );
  }

  final int nativeId;
  final String title;
  final AlarmModel? alarm;
  final bool canSnooze;
}
