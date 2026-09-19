enum ReincarnationStatus { active, completed, cancelled }

class ReincarnationRunModel {
  const ReincarnationRunModel({
    required this.id,
    required this.alarmId,
    required this.originOccurrenceAt,
    required this.remainingCount,
    required this.nextFireAt,
    required this.status,
  });

  final String id;
  final String alarmId;
  final DateTime originOccurrenceAt;
  final int remainingCount;
  final DateTime nextFireAt;
  final ReincarnationStatus status;
}
