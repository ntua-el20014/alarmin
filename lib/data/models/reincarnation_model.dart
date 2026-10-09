enum ReincarnationStatus { active, completed, cancelled }

/// Runtime state of a snooze chain, kept apart from the saved alarm.
///
/// The first snooze schedules every firing of the chain up front:
/// firing `k` happens at `firstFireAt + k * interval` for
/// `k = 0..reincarnationCount`. Firing 0 is the snoozed ring itself; the
/// remaining [reincarnationCount] firings are the reincarnations. Scheduling
/// the whole chain natively means it keeps working while the app is killed.
class ReincarnationRunModel {
  const ReincarnationRunModel({
    required this.id,
    required this.alarmId,
    required this.originOccurrenceAt,
    required this.remainingCount,
    required this.nextFireAt,
    required this.status,
    required this.firstFireAt,
    required this.reincarnationCount,
    required this.interval,
  });

  final String id;
  final String alarmId;
  final DateTime originOccurrenceAt;

  /// Reincarnated firings that have not rung yet.
  final int remainingCount;
  final DateTime nextFireAt;
  final ReincarnationStatus status;
  final DateTime firstFireAt;
  final int reincarnationCount;
  final Duration interval;

  DateTime firingAt(int index) => firstFireAt.add(interval * index);

  List<DateTime> get firingTimes => [
        for (var index = 0; index <= reincarnationCount; index++)
          firingAt(index),
      ];

  bool hasFiringAfter(DateTime moment) =>
      firingAt(reincarnationCount).isAfter(moment);

  ReincarnationRunModel copyWith({
    int? remainingCount,
    DateTime? nextFireAt,
    ReincarnationStatus? status,
  }) {
    return ReincarnationRunModel(
      id: id,
      alarmId: alarmId,
      originOccurrenceAt: originOccurrenceAt,
      remainingCount: remainingCount ?? this.remainingCount,
      nextFireAt: nextFireAt ?? this.nextFireAt,
      status: status ?? this.status,
      firstFireAt: firstFireAt,
      reincarnationCount: reincarnationCount,
      interval: interval,
    );
  }
}
