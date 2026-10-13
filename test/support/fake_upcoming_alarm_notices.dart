import 'dart:async';

import 'package:alarmin/data/services/upcoming_alarm_notices.dart';

class FakeUpcomingAlarmNotices implements UpcomingAlarmNotices {
  /// Scheduled notices by slot.
  final Map<int, UpcomingNotice> active = {};

  /// Skips handed out by the next [takeSkipped].
  final List<SkippedOccurrence> pendingSkips = [];

  @override
  Future<void> schedule(UpcomingNotice notice) async =>
      active[notice.slotId] = notice;

  @override
  Future<void> cancel(int slotId) async => active.remove(slotId);

  @override
  Future<List<SkippedOccurrence>> takeSkipped() async {
    final skips = List.of(pendingSkips);
    pendingSkips.clear();
    return skips;
  }

  @override
  Stream<void> get skipEvents => const Stream.empty();
}
