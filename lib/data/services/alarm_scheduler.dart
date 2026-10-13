import 'dart:async';
import 'dart:io' show Platform;

import 'package:alarm/alarm.dart' as native_alarm;
import 'package:flutter/foundation.dart';

import '../models/ringtone.dart';

/// One native alarm to schedule. Feature code builds these; only
/// [NativeAlarmScheduler] knows about the `alarm` package.
class NativeAlarmRequest {
  const NativeAlarmRequest({
    required this.id,
    required this.dateTime,
    required this.title,
    required this.body,
    required this.ringtone,
    this.vibrate = true,
    this.loopAudio = true,
    this.fadeDuration = Duration.zero,
  });

  final int id;
  final DateTime dateTime;
  final String title;
  final String body;

  /// A [Ringtone] id (or legacy value); resolved to a bundled asset.
  final String ringtone;
  final bool vibrate;
  final bool loopAudio;

  /// How long the volume takes to rise; zero starts at full volume.
  final Duration fadeDuration;
}

abstract interface class AlarmScheduler {
  bool get isSupported;

  /// Native ids of alarms that started ringing.
  Stream<int> get ringEvents;

  /// Native ids of alarms that were set or stopped, including stops made from
  /// the notification while the app runs in the background.
  Stream<int> get updateEvents;

  Future<void> initialize();
  Future<bool> schedule(NativeAlarmRequest request);
  Future<void> cancel(int nativeId);

  /// Ids the plugin still holds (scheduled or ringing). This may contain ids
  /// already stopped natively, but never misses one that is still set.
  Future<Set<int>> scheduledIds();
  Future<bool> isRinging(int nativeId);
}

/// Reserved native ids for alarms that do not belong to an [AlarmModel].
const timerNativeId = 2147483646;
const testAlarmNativeId = 2147483645;

class NativeAlarmScheduler implements AlarmScheduler {
  static Stream<int>? _ringEvents;
  static Stream<int>? _updateEvents;

  Future<void> _tail = Future.value();

  @override
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // The plugin exposes single-subscription controllers; share one listener.
  @override
  Stream<int> get ringEvents =>
      _ringEvents ??= native_alarm.Alarm.ringStream.stream
          .map((settings) => settings.id)
          .asBroadcastStream();

  @override
  Stream<int> get updateEvents => _updateEvents ??=
      native_alarm.Alarm.updateStream.stream.asBroadcastStream();

  @override
  Future<void> initialize() async {
    if (!isSupported) return;
    await native_alarm.Alarm.init(showDebugLogs: kDebugMode);
  }

  @override
  Future<bool> schedule(NativeAlarmRequest request) {
    if (!isSupported) return Future.value(false);
    return _serialized(() async {
      final dateTime = await _freeSecond(request.id, request.dateTime);
      return native_alarm.Alarm.set(
        alarmSettings: native_alarm.AlarmSettings(
          id: request.id,
          dateTime: dateTime,
          assetAudioPath: Ringtone.resolve(request.ringtone).assetPath,
          loopAudio: request.loopAudio,
          vibrate: request.vibrate,
          fadeDuration: request.fadeDuration.inMilliseconds / 1000,
          warningNotificationOnKill: Platform.isIOS,
          androidFullScreenIntent: true,
          notificationSettings: native_alarm.NotificationSettings(
            title: request.title,
            body: request.body,
            stopButton: 'Stop',
            // android/app/src/main/res/drawable/ic_stat_alarm.xml
            icon: 'ic_stat_alarm',
          ),
        ),
      );
    });
  }

  @override
  Future<void> cancel(int nativeId) {
    if (!isSupported) return Future.value();
    return _serialized(() => native_alarm.Alarm.stop(nativeId));
  }

  @override
  Future<Set<int>> scheduledIds() async {
    if (!isSupported) return const <int>{};
    final alarms = await native_alarm.Alarm.getAlarms();
    return {for (final alarm in alarms) alarm.id};
  }

  @override
  Future<bool> isRinging(int nativeId) {
    if (!isSupported) return Future.value(false);
    return native_alarm.Alarm.isRinging(nativeId);
  }

  /// `Alarm.set` silently stops any other alarm set for the same second, so
  /// two alarms at 07:00 would cancel each other. Shift by whole seconds
  /// until the slot is free.
  Future<DateTime> _freeSecond(int id, DateTime dateTime) async {
    final taken = {
      for (final alarm in await native_alarm.Alarm.getAlarms())
        if (alarm.id != id) alarm.dateTime.millisecondsSinceEpoch ~/ 1000,
    };
    var candidate = dateTime;
    while (taken.contains(candidate.millisecondsSinceEpoch ~/ 1000)) {
      candidate = candidate.add(const Duration(seconds: 1));
    }
    return candidate;
  }

  /// The plugin crashes on iOS if set/stop run concurrently.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

int nativeAlarmId(String alarmId) {
  var hash = 2166136261;
  for (final codeUnit in alarmId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  // Keep clear of the invalid ids 0/-1 and of the reserved ids above.
  if (hash == 0 || hash >= testAlarmNativeId) {
    return 1;
  }
  return hash;
}
