import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A quiet notification shown [UpcomingAlarmNotices.leadTime] before an
/// alarm occurrence, with a Skip button that works without opening the app.
class UpcomingNotice {
  const UpcomingNotice({
    required this.slotId,
    required this.alarmId,
    required this.occurrence,
    required this.title,
    required this.nativeIds,
  });

  /// Identifies the notification; a later notice for the same slot replaces
  /// it.
  final int slotId;
  final String alarmId;
  final DateTime occurrence;
  final String title;

  /// Native alarms to cancel when Skip is pressed: the occurrence's ring and
  /// its reminders.
  final List<int> nativeIds;
}

/// An occurrence skipped from a notification.
class SkippedOccurrence {
  const SkippedOccurrence(this.alarmId, this.occurrence);

  final String alarmId;
  final DateTime occurrence;

  @override
  bool operator ==(Object other) =>
      other is SkippedOccurrence &&
      other.alarmId == alarmId &&
      other.occurrence == occurrence;

  @override
  int get hashCode => Object.hash(alarmId, occurrence);
}

abstract interface class UpcomingAlarmNotices {
  static const leadTime = Duration(hours: 1);

  /// Shows [notice] at its time. Scheduling the same occurrence again keeps
  /// the current state, so a notification the user swiped away stays away.
  Future<void> schedule(UpcomingNotice notice);

  /// Removes the notice in [slotId], shown or not.
  Future<void> cancel(int slotId);

  /// Occurrences skipped since the last call. Their native alarms are
  /// already cancelled; the saved alarm still has to move past them.
  Future<List<SkippedOccurrence>> takeSkipped();

  /// Fires when Skip is pressed while the app is running.
  Stream<void> get skipEvents;
}

/// Android implementation; see `UpcomingAlarms.kt`.
class NativeUpcomingAlarmNotices implements UpcomingAlarmNotices {
  static const _channel = MethodChannel('alarmin/upcoming');

  StreamController<void>? _skips;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> schedule(UpcomingNotice notice) => _invoke('schedule', {
        'slot': notice.slotId,
        'alarmId': notice.alarmId,
        'occurrence': notice.occurrence.millisecondsSinceEpoch,
        'title': notice.title,
        'nativeIds': notice.nativeIds,
      });

  @override
  Future<void> cancel(int slotId) => _invoke('cancel', slotId);

  @override
  Future<List<SkippedOccurrence>> takeSkipped() async {
    final raw = await _invoke<List<Object?>>('takeSkipped');
    return [
      for (final entry in raw ?? const <Object?>[])
        if (entry case {'alarmId': String id, 'occurrence': int at})
          SkippedOccurrence(id, DateTime.fromMillisecondsSinceEpoch(at)),
    ];
  }

  @override
  Stream<void> get skipEvents {
    final existing = _skips;
    if (existing != null) return existing.stream;
    final skips = _skips = StreamController<void>.broadcast();
    if (_isSupported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'skipped') skips.add(null);
      });
    }
    return skips.stream;
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!_isSupported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null; // Not running in MainActivity (tests, other embedders).
    }
  }
}
