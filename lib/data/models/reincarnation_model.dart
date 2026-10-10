enum ReincarnationStatus { active, completed, cancelled }

/// The reminder rings ("reincarnations") that follow one occurrence of an
/// alarm, kept apart from the saved alarm definition.
///
/// An occurrence at `T` with [reminderCount] reminders every [interval]
/// also rings at `T + k * interval` for `k = 1..reminderCount`. Reminders are
/// scheduled natively together with the occurrence, so stopping the first
/// ring by accident (or from the notification) does not cancel them; only
/// an explicit "turn off reminders" does.
class ReincarnationRunModel {
  const ReincarnationRunModel({
    required this.id,
    required this.alarmId,
    required this.originOccurrenceAt,
    required this.reminderCount,
    required this.interval,
    required this.remainingCount,
    required this.nextFireAt,
    required this.status,
  });

  factory ReincarnationRunModel.forOccurrence({
    required String alarmId,
    required DateTime occurrence,
    required int reminderCount,
    required Duration interval,
  }) {
    return ReincarnationRunModel(
      id: idFor(alarmId, occurrence),
      alarmId: alarmId,
      originOccurrenceAt: occurrence,
      reminderCount: reminderCount,
      interval: interval,
      remainingCount: reminderCount,
      nextFireAt: occurrence.add(interval),
      status: ReincarnationStatus.active,
    );
  }

  static String idFor(String alarmId, DateTime occurrence) =>
      'run-$alarmId-${occurrence.millisecondsSinceEpoch}';

  final String id;
  final String alarmId;

  /// The regular occurrence these reminders follow.
  final DateTime originOccurrenceAt;
  final int reminderCount;
  final Duration interval;

  /// Reminders that have not rung yet.
  final int remainingCount;
  final DateTime nextFireAt;
  final ReincarnationStatus status;

  /// Reminder [index] (1-based) rings at this time.
  DateTime reminderAt(int index) => originOccurrenceAt.add(interval * index);

  List<DateTime> remindersAfter(DateTime moment) => [
        for (var index = 1; index <= reminderCount; index++)
          if (reminderAt(index).isAfter(moment)) reminderAt(index),
      ];

  bool hasReminderAfter(DateTime moment) =>
      reminderCount > 0 && reminderAt(reminderCount).isAfter(moment);

  ReincarnationRunModel copyWith({
    int? remainingCount,
    DateTime? nextFireAt,
    ReincarnationStatus? status,
  }) {
    return ReincarnationRunModel(
      id: id,
      alarmId: alarmId,
      originOccurrenceAt: originOccurrenceAt,
      reminderCount: reminderCount,
      interval: interval,
      remainingCount: remainingCount ?? this.remainingCount,
      nextFireAt: nextFireAt ?? this.nextFireAt,
      status: status ?? this.status,
    );
  }
}
