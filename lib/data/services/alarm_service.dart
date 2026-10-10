import '../models/alarm_model.dart';
import '../models/recurrence_rule.dart';
import '../models/reincarnation_model.dart';
import '../models/ringing_alarm.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/reincarnation_repository.dart';
import 'alarm_scheduler.dart';

/// Upper bound for [AlarmModel.reincarnationCount] (reminders per
/// occurrence); each reminder owns a native id.
const maxReincarnationCount = 10;

/// Native ids an alarm owns:
/// - primary: the next regular occurrence;
/// - follow-up: the occurrence after that, so a recurring alarm still rings
///   tomorrow when today's ring was stopped from the notification while the
///   app was killed and could not reschedule;
/// - snooze: the pending snoozed ring;
/// - reminder: reminder `k` after a given occurrence. Keyed by the
///   occurrence, so moving the primary slot to tomorrow never cancels
///   today's pending reminders.
int primaryNativeId(String alarmId) => nativeAlarmId(alarmId);
int followUpNativeId(String alarmId) => nativeAlarmId('$alarmId#next');
int snoozeNativeId(String alarmId) => nativeAlarmId('$alarmId#snooze');
int reminderNativeId(String alarmId, DateTime occurrence, int index) =>
    nativeAlarmId('$alarmId@${occurrence.millisecondsSinceEpoch}#r$index');

/// Ids used by the earlier snooze-chain design, cleaned up on recovery.
Iterable<int> _legacyNativeIds(String alarmId) => [
      for (var index = 0; index <= maxReincarnationCount; index++)
        nativeAlarmId('$alarmId#r$index'),
    ];

class AlarmSchedulingException implements Exception {
  AlarmSchedulingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns every change to an alarm's saved state and native schedule.
///
/// UI actions, ring events, and native stop events all run through one
/// serial queue, so they can never interleave.
class AlarmService {
  AlarmService({
    required AlarmRepository repository,
    required ReincarnationRepository reincarnationRepository,
    required AlarmScheduler scheduler,
    CategoryRepository? categoryRepository,
    DateTime Function()? now,
  })  : _repository = repository,
        _reincarnationRepository = reincarnationRepository,
        _categoryRepository = categoryRepository,
        _scheduler = scheduler,
        _now = now ?? DateTime.now;

  /// How long after its due time a ring that has not started yet is left
  /// alone during recovery, so recovery does not race the native trigger.
  static const _ringGrace = Duration(minutes: 1);

  final AlarmRepository _repository;
  final ReincarnationRepository _reincarnationRepository;
  final CategoryRepository? _categoryRepository;
  final AlarmScheduler _scheduler;
  final DateTime Function() _now;

  Future<void> _tail = Future.value();

  Future<void> initialize() => _scheduler.initialize();

  /// Brings every alarm's native schedule in line with the database. Runs at
  /// startup, whenever the app returns to the foreground, and after a
  /// category edit (notification titles carry the category emoji).
  Future<void> recover() => _serialized(() async {
        for (final alarm in await _repository.getAll()) {
          await _reconcile(alarm, recovering: true);
        }
      });

  /// Reacts to a native alarm being stopped outside the app, for example from
  /// the notification's Stop button.
  Future<void> handleNativeUpdate(int nativeId) => _serialized(() async {
        final match = await _match(nativeId);
        if (match != null) await _reconcile(match.alarm, recovering: false);
      });

  Future<AlarmModel> save(AlarmModel alarm) => _serialized(() async {
        await _cancelEverything(alarm.id);
        return _scheduleRegular(alarm);
      });

  Future<AlarmModel> setEnabled(AlarmModel alarm, bool isEnabled) {
    return save(alarm.copyWith(isEnabled: isEnabled, updatedAt: _now()));
  }

  Future<void> delete(AlarmModel alarm) => _serialized(() async {
        await _cancelEverything(alarm.id);
        await _repository.delete(alarm.id);
      });

  /// Describes the ring of [nativeId] for the UI and records reminder
  /// progress. Returns null when the id does not belong to a saved alarm.
  Future<RingingAlarm?> handleRing(int nativeId) => _serialized(() async {
        final match = await _match(nativeId);
        if (match == null) return null;
        final alarm = match.alarm;
        final run = match.run;
        final index = match.reminderIndex;
        if (run != null && index != null) {
          await _reincarnationRepository.save(
            run.copyWith(
              remainingCount: run.reminderCount - index,
              nextFireAt: run.reminderAt(
                index < run.reminderCount ? index + 1 : index,
              ),
            ),
          );
        }
        return RingingAlarm(
          nativeId: nativeId,
          title: alarm.title,
          alarm: alarm,
          canSnooze: true,
          upcomingReminders: await _upcomingReminders(alarm.id),
        );
      });

  /// Silences the ring and rings once more after the snooze duration.
  /// Pending reminders are unaffected.
  Future<void> snooze(AlarmModel alarm, {int? ringingNativeId}) =>
      _serialized(() async {
        final current = await _repository.findById(alarm.id) ?? alarm;
        await _stopRinging(current.id, ringingNativeId);
        await _set(
          snoozeNativeId(current.id),
          _now().add(current.snoozeDuration),
          current,
          body: 'Snoozed',
        );
        await _advance(current);
      });

  /// Stops this ring. Reminders that are still to come keep ringing; that is
  /// what protects against stopping an alarm by accident.
  Future<void> dismiss(AlarmModel alarm, {int? ringingNativeId}) =>
      _serialized(() async {
        await _stopRinging(alarm.id, ringingNativeId);
        await _cancelIds([snoozeNativeId(alarm.id)]);
        final current = await _repository.findById(alarm.id);
        if (current != null) await _advance(current);
      });

  /// Stops this ring and cancels every pending reminder and snooze of
  /// occurrences that have already started. Future occurrences keep theirs.
  Future<void> dismissAll(AlarmModel alarm, {int? ringingNativeId}) =>
      _serialized(() async {
        await _stopRinging(alarm.id, ringingNativeId);
        await _cancelIds([snoozeNativeId(alarm.id)]);
        final now = _now();
        for (final run
            in await _reincarnationRepository.activeForAlarm(alarm.id)) {
          if (run.originOccurrenceAt.isAfter(now)) continue;
          await _cancelIds(_reminderIds(alarm.id, run));
          await _reincarnationRepository.delete(run.id);
        }
        final current = await _repository.findById(alarm.id);
        if (current != null) await _advance(current);
      });

  /// After a ring was handled: moves a recurring alarm on to its next
  /// occurrence, or completes a one-time alarm once nothing is left to ring.
  Future<void> _advance(AlarmModel alarm) async {
    final now = _now();
    await _completeFinishedRuns(alarm.id, now);
    if (alarm.recurrence.scheduleType != AlarmScheduleType.once) {
      await _scheduleRegular(alarm);
      return;
    }
    final snoozed =
        (await _scheduler.scheduledIds()).contains(snoozeNativeId(alarm.id));
    if (!snoozed && (await _upcomingReminders(alarm.id)).isEmpty) {
      await _finishOneTime(alarm);
    }
  }

  Future<void> _reconcile(
    AlarmModel alarm, {
    required bool recovering,
  }) async {
    final scheduled = await _scheduler.scheduledIds();
    final runs = await _reincarnationRepository.activeForAlarm(alarm.id);
    final ownIds = {
      primaryNativeId(alarm.id),
      followUpNativeId(alarm.id),
      snoozeNativeId(alarm.id),
      ..._legacyNativeIds(alarm.id),
      for (final run in runs) ..._reminderIds(alarm.id, run),
    };
    for (final id in ownIds.where(scheduled.contains)) {
      // The ring screen or notification owns a ringing alarm.
      if (await _scheduler.isRinging(id)) return;
    }

    final now = _now();
    final settled = recovering ? now.subtract(_ringGrace) : now;
    final expected = [
      if (alarm.isEnabled && alarm.nextOccurrenceAt != null)
        alarm.nextOccurrenceAt!,
      for (final run in runs)
        for (var index = 1; index <= run.reminderCount; index++)
          run.reminderAt(index),
    ];
    if (expected.any((at) => at.isAfter(settled) && !at.isAfter(now))) {
      return; // Due this very moment; let the native alarm fire first.
    }

    if (recovering) await _cancelIds(_legacyNativeIds(alarm.id));
    await _completeFinishedRuns(alarm.id, settled);

    if (!alarm.isEnabled) {
      if (recovering) await _cancelEverything(alarm.id);
      return;
    }

    final pendingRuns = [
      for (final run in runs)
        if (run.hasReminderAfter(now)) run,
    ];

    if (alarm.recurrence.scheduleType == AlarmScheduleType.once) {
      if (alarm.recurrence.nextOccurrenceAfter(now) == null) {
        final snoozed = scheduled.contains(snoozeNativeId(alarm.id));
        if (pendingRuns.isEmpty && !snoozed) {
          await _finishOneTime(alarm);
        } else if (recovering) {
          for (final run in pendingRuns) {
            await _setReminders(alarm, run, now);
          }
        }
      } else if (recovering) {
        await _scheduleRegular(alarm);
      }
      return;
    }

    final occurrence = alarm.nextOccurrenceAt;
    final isDue = occurrence == null || !occurrence.isAfter(now);
    if (recovering || isDue) await _scheduleRegular(alarm);
    if (recovering) {
      // Reminders of occurrences that already rang but are not over yet.
      for (final run in pendingRuns) {
        if (!run.originOccurrenceAt.isAfter(now)) {
          await _setReminders(alarm, run, now);
        }
      }
    }
  }

  /// Saves [alarm] with its next occurrence and schedules the primary and
  /// follow-up occurrences together with their reminders. Leaves pending
  /// reminders of past occurrences and any snooze untouched.
  Future<AlarmModel> _scheduleRegular(AlarmModel alarm) async {
    final now = _now();
    final next = alarm.recurrence.nextOccurrenceAfter(now);
    final updated = next == null
        ? alarm.copyWith(clearNextOccurrenceAt: true)
        : alarm.copyWith(nextOccurrenceAt: next);
    await _repository.save(updated);
    await _cancelIds([
      primaryNativeId(updated.id),
      followUpNativeId(updated.id),
    ]);
    if (!updated.isEnabled || next == null) return updated;

    final title = await _notificationTitle(updated);
    await _set(primaryNativeId(updated.id), next, updated,
        title: title, body: _occurrenceBody(updated));
    await _ensureReminders(updated, next, title);
    if (updated.recurrence.scheduleType != AlarmScheduleType.once) {
      final following = updated.recurrence.nextOccurrenceAfter(next);
      if (following != null) {
        await _set(followUpNativeId(updated.id), following, updated,
            title: title, body: _occurrenceBody(updated));
        await _ensureReminders(updated, following, title);
      }
    }
    return updated;
  }

  Future<void> _ensureReminders(
    AlarmModel alarm,
    DateTime occurrence,
    String title,
  ) async {
    final count =
        alarm.reincarnationCount.clamp(0, maxReincarnationCount).toInt();
    if (count == 0) return;
    final existing = await _reincarnationRepository.findById(
      ReincarnationRunModel.idFor(alarm.id, occurrence),
    );
    final run = existing ??
        ReincarnationRunModel.forOccurrence(
          alarmId: alarm.id,
          occurrence: occurrence,
          reminderCount: count,
          interval: alarm.reincarnationInterval,
        );
    if (existing == null) await _reincarnationRepository.save(run);
    await _setReminders(alarm, run, _now(), title: title);
  }

  Future<void> _setReminders(
    AlarmModel alarm,
    ReincarnationRunModel run,
    DateTime now, {
    String? title,
  }) async {
    final notificationTitle = title ?? await _notificationTitle(alarm);
    for (var index = 1; index <= run.reminderCount; index++) {
      final at = run.reminderAt(index);
      if (!at.isAfter(now)) continue;
      await _set(
        reminderNativeId(alarm.id, run.originOccurrenceAt, index),
        at,
        alarm,
        title: notificationTitle,
        body: 'Reminder $index of ${run.reminderCount}',
      );
    }
  }

  Future<void> _completeFinishedRuns(String alarmId, DateTime moment) async {
    for (final run in await _reincarnationRepository.activeForAlarm(alarmId)) {
      // Ended runs are runtime state only; reminders are only ever created
      // for future occurrences, so nothing needs to remember them.
      if (!run.hasReminderAfter(moment)) {
        await _reincarnationRepository.delete(run.id);
      }
    }
  }

  Future<List<DateTime>> _upcomingReminders(String alarmId) async {
    final now = _now();
    return [
      for (final run in await _reincarnationRepository.activeForAlarm(alarmId))
        if (!run.originOccurrenceAt.isAfter(now)) ...run.remindersAfter(now),
    ]..sort();
  }

  Future<void> _finishOneTime(AlarmModel alarm) async {
    await _cancelEverything(alarm.id);
    if (alarm.deleteAfterUse) {
      await _repository.delete(alarm.id);
      return;
    }
    await _repository.save(
      alarm.copyWith(
        isEnabled: false,
        clearNextOccurrenceAt: true,
        updatedAt: _now(),
      ),
    );
  }

  /// Cancels every native alarm of [alarmId] and forgets its reminder runs.
  Future<void> _cancelEverything(String alarmId) async {
    final runs = await _reincarnationRepository.activeForAlarm(alarmId);
    await _cancelIds([
      primaryNativeId(alarmId),
      followUpNativeId(alarmId),
      snoozeNativeId(alarmId),
      ..._legacyNativeIds(alarmId),
      for (final run in runs) ..._reminderIds(alarmId, run),
    ]);
    await _reincarnationRepository.deleteForAlarm(alarmId);
  }

  Future<void> _stopRinging(String alarmId, int? ringingNativeId) async {
    if (ringingNativeId != null) {
      await _cancelIds([ringingNativeId]);
      return;
    }
    // Unknown which id rings: stop whichever of the alarm's ids is ringing.
    final scheduled = await _scheduler.scheduledIds();
    final runs = await _reincarnationRepository.activeForAlarm(alarmId);
    for (final id in {
      primaryNativeId(alarmId),
      followUpNativeId(alarmId),
      snoozeNativeId(alarmId),
      for (final run in runs) ..._reminderIds(alarmId, run),
    }) {
      if (scheduled.contains(id) && await _scheduler.isRinging(id)) {
        await _scheduler.cancel(id);
      }
    }
  }

  Iterable<int> _reminderIds(String alarmId, ReincarnationRunModel run) => [
        for (var index = 1; index <= run.reminderCount; index++)
          reminderNativeId(alarmId, run.originOccurrenceAt, index),
      ];

  Future<String> _notificationTitle(AlarmModel alarm) async {
    final categoryId = alarm.categoryId;
    final category = categoryId == null
        ? null
        : await _categoryRepository?.findById(categoryId);
    return category == null ? alarm.title : '${category.emoji} ${alarm.title}';
  }

  String _occurrenceBody(AlarmModel alarm) {
    final count = alarm.reincarnationCount;
    if (count <= 0) return 'Alarm';
    final minutes = alarm.reincarnationInterval.inMinutes;
    return count == 1
        ? 'Reminder in $minutes min'
        : '$count reminders, every $minutes min';
  }

  Future<void> _set(
    int nativeId,
    DateTime dateTime,
    AlarmModel alarm, {
    String? title,
    String body = 'Alarm',
  }) async {
    if (!_scheduler.isSupported) return;
    final scheduled = await _scheduler.schedule(
      NativeAlarmRequest(
        id: nativeId,
        dateTime: dateTime,
        title: title ?? await _notificationTitle(alarm),
        body: body,
        ringtone: alarm.ringtone,
        vibrate: alarm.vibration != VibrationSetting.off,
      ),
    );
    if (!scheduled) {
      throw AlarmSchedulingException(
        'The system refused to schedule "${alarm.title}". '
        'Check that notifications and alarms are allowed for Alarmin.',
      );
    }
  }

  Future<void> _cancelIds(Iterable<int> ids) async {
    if (!_scheduler.isSupported) return;
    final scheduled = await _scheduler.scheduledIds();
    for (final id in ids) {
      if (scheduled.contains(id)) await _scheduler.cancel(id);
    }
  }

  Future<_NativeMatch?> _match(int nativeId) async {
    for (final alarm in await _repository.getAll()) {
      final id = alarm.id;
      if (nativeId == primaryNativeId(id) ||
          nativeId == followUpNativeId(id) ||
          nativeId == snoozeNativeId(id) ||
          _legacyNativeIds(id).contains(nativeId)) {
        return _NativeMatch(alarm);
      }
      for (final run in await _reincarnationRepository.activeForAlarm(id)) {
        for (var index = 1; index <= run.reminderCount; index++) {
          if (reminderNativeId(id, run.originOccurrenceAt, index) == nativeId) {
            return _NativeMatch(alarm, run: run, reminderIndex: index);
          }
        }
      }
    }
    return null;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

class _NativeMatch {
  const _NativeMatch(this.alarm, {this.run, this.reminderIndex});

  final AlarmModel alarm;
  final ReincarnationRunModel? run;
  final int? reminderIndex;
}
