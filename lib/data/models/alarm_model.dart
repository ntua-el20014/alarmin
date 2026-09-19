import 'recurrence_rule.dart';

enum VibrationSetting { off, standard }

class AlarmModel {
  const AlarmModel({
    required this.id,
    required this.title,
    required this.recurrence,
    required this.isEnabled,
    required this.deleteAfterUse,
    required this.ringtone,
    required this.vibration,
    required this.snoozeDuration,
    required this.reincarnationCount,
    required this.reincarnationInterval,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.nextOccurrenceAt,
  }) : assert(reincarnationCount >= 0);

  final String id;
  final String title;
  final String? categoryId;
  final RecurrenceRule recurrence;
  final bool isEnabled;
  final bool deleteAfterUse;
  final String ringtone;
  final VibrationSetting vibration;
  final Duration snoozeDuration;
  final int reincarnationCount;
  final Duration reincarnationInterval;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextOccurrenceAt;
}
