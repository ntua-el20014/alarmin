import 'dart:async';

import 'package:alarmin/data/services/alarm_scheduler.dart';

/// In-memory stand-in for the native alarm plugin.
class FakeAlarmScheduler implements AlarmScheduler {
  final ringController = StreamController<int>.broadcast();
  final updateController = StreamController<int>.broadcast();

  /// Every request ever scheduled, in order.
  final scheduled = <NativeAlarmRequest>[];

  /// Every native id ever cancelled, in order.
  final cancelled = <int>[];

  /// What the plugin currently holds, by native id.
  final active = <int, NativeAlarmRequest>{};
  final ringing = <int>{};

  /// Starts ringing [nativeId], as the plugin would at its due time.
  void ring(int nativeId) {
    ringing.add(nativeId);
    ringController.add(nativeId);
  }

  /// Stops [nativeId] the way the notification's Stop button does.
  void stopFromNotification(int nativeId) {
    ringing.remove(nativeId);
    active.remove(nativeId);
    updateController.add(nativeId);
  }

  @override
  bool get isSupported => true;

  @override
  Stream<int> get ringEvents => ringController.stream;

  @override
  Stream<int> get updateEvents => updateController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NativeAlarmRequest request) async {
    scheduled.add(request);
    active[request.id] = request;
    return true;
  }

  @override
  Future<void> cancel(int nativeId) async {
    cancelled.add(nativeId);
    active.remove(nativeId);
    ringing.remove(nativeId);
  }

  @override
  Future<Set<int>> scheduledIds() async => active.keys.toSet();

  @override
  Future<bool> isRinging(int nativeId) async => ringing.contains(nativeId);

  Future<void> close() async {
    await ringController.close();
    await updateController.close();
  }
}
