enum AlarmScheduleType { once, daily, weekly, intervalDays }

class RecurrenceRule {
  const RecurrenceRule({
    required this.scheduleType,
    required this.timeOfDay,
    this.scheduledDate,
    this.daysOfWeek = const <int>{},
    this.intervalDays,
    this.scheduleStartDate,
    this.scheduleEndDate,
  })  : assert(timeOfDay >= 0 && timeOfDay < 24 * 60),
        assert(scheduleType != AlarmScheduleType.once || scheduledDate != null),
        assert(
            scheduleType != AlarmScheduleType.weekly || daysOfWeek.length > 0),
        assert(
          scheduleType != AlarmScheduleType.intervalDays ||
              (intervalDays != null &&
                  intervalDays > 0 &&
                  scheduleStartDate != null),
        );

  final AlarmScheduleType scheduleType;
  final int timeOfDay;
  final DateTime? scheduledDate;
  final Set<int> daysOfWeek;
  final int? intervalDays;
  final DateTime? scheduleStartDate;
  final DateTime? scheduleEndDate;

  DateTime? nextOccurrenceAfter(DateTime after) {
    switch (scheduleType) {
      case AlarmScheduleType.once:
        final occurrence = _atTime(scheduledDate!);
        return occurrence.isAfter(after) ? occurrence : null;
      case AlarmScheduleType.daily:
        return _nextDaily(after);
      case AlarmScheduleType.weekly:
        return _nextWeekly(after);
      case AlarmScheduleType.intervalDays:
        return _nextInterval(after);
    }
  }

  // All day steps use calendar arithmetic (`DateTime(y, m, d + n)`), never
  // `Duration(days: n)`: a Duration is a fixed 24 h, so across a daylight-
  // saving change it lands an hour off, which made a 07:00 alarm ring at
  // 06:00 and could return the same occurrence forever.

  DateTime _atTime(DateTime date, [int addDays = 0]) {
    return DateTime(date.year, date.month, date.day + addDays, timeOfDay ~/ 60,
        timeOfDay % 60);
  }

  /// Whole calendar days from [from] to [to], ignoring clock changes.
  static int _daysBetween(DateTime from, DateTime to) {
    return DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
  }

  DateTime? _nextDaily(DateTime after) {
    var candidate = _atTime(after);
    if (!candidate.isAfter(after)) {
      candidate = _atTime(after, 1);
    }
    return _withinEndDate(candidate);
  }

  DateTime? _nextWeekly(DateTime after) {
    for (var offset = 0; offset < 8; offset++) {
      final date = DateTime(after.year, after.month, after.day + offset);
      final candidate = _atTime(date);
      if (daysOfWeek.contains(candidate.weekday) && candidate.isAfter(after)) {
        return _withinEndDate(candidate);
      }
    }
    return null;
  }

  DateTime? _nextInterval(DateTime after) {
    final startDate = DateTime(
      scheduleStartDate!.year,
      scheduleStartDate!.month,
      scheduleStartDate!.day,
    );
    final afterDate = DateTime(after.year, after.month, after.day);
    if (afterDate.isBefore(startDate)) {
      return _withinEndDate(_atTime(startDate));
    }

    final daysSinceStart = _daysBetween(startDate, afterDate);
    var occurrenceIndex = daysSinceStart ~/ intervalDays!;
    var candidate = _atTime(startDate, occurrenceIndex * intervalDays!);
    if (!candidate.isAfter(after)) {
      occurrenceIndex++;
      candidate = _atTime(startDate, occurrenceIndex * intervalDays!);
    }
    return _withinEndDate(candidate);
  }

  DateTime? _withinEndDate(DateTime candidate) {
    if (scheduleEndDate == null) {
      return candidate;
    }
    final endDate = DateTime(scheduleEndDate!.year, scheduleEndDate!.month,
        scheduleEndDate!.day, 23, 59);
    return candidate.isAfter(endDate) ? null : candidate;
  }
}
