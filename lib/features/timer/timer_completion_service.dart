import '../../data/services/alarm_scheduler.dart';

/// Schedules the timer's completion as a native alarm, so it rings even when
/// the app is in the background or the screen is off.
abstract interface class TimerCompletionNotifier {
  Future<void> scheduleCompletion(DateTime at);
  Future<void> cancel();
}

class NativeTimerCompletionNotifier implements TimerCompletionNotifier {
  NativeTimerCompletionNotifier(this._scheduler, this._ringtone);

  final AlarmScheduler _scheduler;
  final String Function() _ringtone;

  @override
  Future<void> scheduleCompletion(DateTime at) async {
    if (!_scheduler.isSupported) return;
    await _scheduler.schedule(
      NativeAlarmRequest(
        id: timerNativeId,
        dateTime: at,
        title: 'Timer finished',
        body: 'Your timer has finished.',
        ringtone: _ringtone(),
      ),
    );
  }

  @override
  Future<void> cancel() async {
    if (!_scheduler.isSupported) return;
    if ((await _scheduler.scheduledIds()).contains(timerNativeId)) {
      await _scheduler.cancel(timerNativeId);
    }
  }
}
