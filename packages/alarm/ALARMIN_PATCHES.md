# Local patches to `alarm` 4.1.1

This is a vendored copy of the `alarm` plugin (MIT, see LICENSE), used through
a path dependency in the app's `pubspec.yaml`. The `example/` folder was
removed. Changes:

- `android/.../services/AudioService.kt`: the `MediaPlayer` uses
  `AudioAttributes.USAGE_ALARM`, so alarms play on the alarm stream and follow
  the alarm volume, not the media volume.
- `android/.../services/VolumeService.kt`: volume control uses
  `STREAM_ALARM` instead of `STREAM_MUSIC`, to match.

- `android/.../alarm/AlarmService.kt`: when an alarm starts it turns the
  screen on (`SCREEN_BRIGHT_WAKE_LOCK | ACQUIRE_CAUSES_WAKEUP`) and, if the app
  may draw over other apps, opens the app directly. This no longer relies on
  Android honouring the full-screen intent, which Android 14+ downgrades to a
  plain notification without the full-screen permission.

- New optional `ringTimeout` (seconds, Android only) on `AlarmSettings`,
  hand-added to `pigeons/alarm_api.dart`, both generated bindings
  (`platform_bindings.g.dart`, `FlutterBindings.g.kt`; the Swift bindings were
  left alone and the Dart decoder tolerates its absence), the Kotlin
  `AlarmSettings` model and the intent extras in `AlarmApiImpl.kt`. If the
  bindings are ever regenerated with pigeon, keep the field last.
- `android/.../alarm/AlarmService.kt`: when `ringTimeout` is set, a ring
  nobody answers stops by itself after that long, the same way as a Stop
  from the notification (`unsaveAlarm`), so Flutter gets `alarmStopped` and
  reschedules. The timeout runs natively, so it also works while the app is
  killed. It is cancelled when the alarm is stopped any other way.

Re-apply these if the plugin is upgraded.
