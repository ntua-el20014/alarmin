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
    this.skippedOccurrenceAt,
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

  /// An occurrence the user skipped from the upcoming alarm notification;
  /// scheduling moves past it. Cleared once it has passed or the alarm is
  /// edited.
  final DateTime? skippedOccurrenceAt;

  AlarmModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    bool clearCategoryId = false,
    RecurrenceRule? recurrence,
    bool? isEnabled,
    bool? deleteAfterUse,
    String? ringtone,
    VibrationSetting? vibration,
    Duration? snoozeDuration,
    int? reincarnationCount,
    Duration? reincarnationInterval,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextOccurrenceAt,
    bool clearNextOccurrenceAt = false,
    DateTime? skippedOccurrenceAt,
    bool clearSkippedOccurrenceAt = false,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: clearCategoryId ? null : categoryId ?? this.categoryId,
      recurrence: recurrence ?? this.recurrence,
      isEnabled: isEnabled ?? this.isEnabled,
      deleteAfterUse: deleteAfterUse ?? this.deleteAfterUse,
      ringtone: ringtone ?? this.ringtone,
      vibration: vibration ?? this.vibration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      reincarnationCount: reincarnationCount ?? this.reincarnationCount,
      reincarnationInterval:
          reincarnationInterval ?? this.reincarnationInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextOccurrenceAt: clearNextOccurrenceAt
          ? null
          : nextOccurrenceAt ?? this.nextOccurrenceAt,
      skippedOccurrenceAt: clearSkippedOccurrenceAt
          ? null
          : skippedOccurrenceAt ?? this.skippedOccurrenceAt,
    );
  }
}
