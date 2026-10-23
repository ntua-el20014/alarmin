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

- `android/.../alarm/AlarmService.kt`: a ring nobody answers stops by itself
  after `RING_TIMEOUT_MS` (40 s), the same way as a Stop from the
  notification (`unsaveAlarm`), so Flutter gets `alarmStopped` and
  reschedules. The timeout runs natively, so it also works while the app is
  killed. It is cancelled when the alarm is stopped any other way.

Re-apply these if the plugin is upgraded.
