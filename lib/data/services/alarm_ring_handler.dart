import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alarm_model.dart';
import '../models/ringing_alarm.dart';
import 'alarm_scheduler.dart';
import 'alarm_service.dart';

/// Bridges native alarm events to [AlarmService] and publishes the alarm
/// that is currently ringing, which drives the ring screen.
class AlarmRingHandler {
  AlarmRingHandler({
    required AlarmService alarmService,
    required AlarmScheduler scheduler,
    required ValueNotifier<RingingAlarm?> ringing,
  })  : _alarmService = alarmService,
        _scheduler = scheduler,
        _ringing = ringing;

  final AlarmService _alarmService;
  final AlarmScheduler _scheduler;
  final ValueNotifier<RingingAlarm?> _ringing;

  StreamSubscription<int>? _ringSubscription;
  StreamSubscription<int>? _updateSubscription;

  void start() {
    _ringSubscription ??= _scheduler.ringEvents
        .listen((nativeId) => _guard(() => handleNativeRing(nativeId)));
    _updateSubscription ??= _scheduler.updateEvents
        .listen((nativeId) => _guard(() => _handleNativeUpdate(nativeId)));
  }

  Future<void> dispose() async {
    await _ringSubscription?.cancel();
    await _updateSubscription?.cancel();
    _ringSubscription = null;
    _updateSubscription = null;
  }

  Future<RingingAlarm> handleNativeRing(int nativeId) async {
    final ringing = await _alarmService.handleRing(nativeId) ??
        RingingAlarm.standalone(nativeId);
    _ringing.value = ringing;
    return ringing;
  }

  Future<void> snooze(AlarmModel alarm, {int? nativeId}) async {
    try {
      await _alarmService.snooze(alarm, ringingNativeId: nativeId);
    } finally {
      _clearIfAlarm(alarm.id);
    }
  }

  Future<void> dismiss(AlarmModel alarm) async {
    try {
      await _alarmService.dismiss(alarm);
    } finally {
      _clearIfAlarm(alarm.id);
    }
  }

  /// Stops [ringing], dismissing it when it belongs to a saved alarm.
  Future<void> stop(RingingAlarm ringing) async {
    final alarm = ringing.alarm;
    if (alarm != null) return dismiss(alarm);
    try {
      await _scheduler.cancel(ringing.nativeId);
    } finally {
      if (_ringing.value?.nativeId == ringing.nativeId) _ringing.value = null;
    }
  }

  Future<void> _handleNativeUpdate(int nativeId) async {
    await _alarmService.handleNativeUpdate(nativeId);
    // Stopped from the notification: close the ring screen as well.
    final current = _ringing.value;
    if (current != null &&
        current.nativeId == nativeId &&
        !await _scheduler.isRinging(nativeId)) {
      _ringing.value = null;
    }
  }

  void _clearIfAlarm(String alarmId) {
    if (_ringing.value?.alarm?.id == alarmId) _ringing.value = null;
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Alarm event handling failed: $error\n$stackTrace');
    }
  }
}
