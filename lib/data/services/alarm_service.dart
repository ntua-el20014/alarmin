import '../models/alarm_model.dart';
import '../models/recurrence_rule.dart';
import '../models/reincarnation_model.dart';
import '../models/ringing_alarm.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/reincarnation_repository.dart';
import 'alarm_scheduler.dart';

/// Upper bound for [AlarmModel.reincarnationCount]; each reincarnation owns a
/// native id, so the set of ids per alarm must be finite.
const maxReincarnationCount = 10;

/// Each alarm owns a fixed group of native ids:
/// - primary: the next regular occurrence;
/// - follow-up: the occurrence after that, so a recurring alarm still rings
///   tomorrow when today's ring was stopped from the notification while the
///   app was killed and could not reschedule;
/// - reincarnation `k`: firing `k` of an active snooze chain.
int primaryNativeId(String alarmId) => nativeAlarmId(alarmId);
int followUpNativeId(String alarmId) => nativeAlarmId('$alarmId#next');
int reincarnationNativeId(String alarmId, int index) =>
    nativeAlarmId('$alarmId#r$index');

Set<int> nativeIdsFor(String alarmId) => {
      primaryNativeId(alarmId),
      followUpNativeId(alarmId),
      for (var index = 0; index <= maxReincarnationCount; index++)
        reincarnationNativeId(alarmId, index),
    };

class AlarmSchedulingException implements Exception {
  AlarmSchedulingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns every change to an alarm's saved state and native schedule.
///
/// UI actions, ring events, and native stop events all run through one
/// serial queue, so a snooze can never be overwritten by a concurrent
/// recovery pass.
class AlarmService {
  AlarmService({
    required AlarmRepository repository,
    required ReincarnationRepository reincarnationRepository,
    required AlarmScheduler scheduler,
    DateTime Function()? now,
  })  : _repository = repository,
        _reincarnationRepository = reincarnationRepository,
        _scheduler = scheduler,
        _now = now ?? DateTime.now;

  /// How long after its due time an alarm that is not ringing yet is left
  /// alone during recovery, so recovery does not race the native trigger.
  static const _ringGrace = Duration(minutes: 1);

  final AlarmRepository _repository;
  final ReincarnationRepository _reincarnationRepository;
  final AlarmScheduler _scheduler;
  final DateTime Function() _now;

  Future<void> _tail = Future.value();

  Future<void> initialize() => _scheduler.initialize();

  /// Brings every alarm's native schedule in line with the database. Runs at
  /// startup and whenever the app returns to the foreground.
  Future<void> recover() => _serialized(() async {
        for (final alarm in await _repository.getAll()) {
          await _reconcile(alarm, recovering: true);
        }
      });

  /// Reacts to a native alarm being stopped outside the app, for example from
  /// the notification's Stop button.
  Future<void> handleNativeUpdate(int nativeId) => _serialized(() async {
        final alarm = await _findByNativeId(nativeId);
        if (alarm != null) await _reconcile(alarm, recovering: false);
      });

  Future<AlarmModel> save(AlarmModel alarm) => _serialized(() async {
        await _reincarnationRepository.cancelForAlarm(alarm.id);
        await _cancelNative(alarm.id);
        return _scheduleRegular(alarm);
      });

  Future<AlarmModel> setEnabled(AlarmModel alarm, bool isEnabled) {
    return save(alarm.copyWith(isEnabled: isEnabled, updatedAt: _now()));
  }

  Future<void> delete(AlarmModel alarm) => _serialized(() async {
        await _cancelNative(alarm.id);
        await _reincarnationRepository.cancelForAlarm(alarm.id);
        await _repository.delete(alarm.id);
      });

  /// Records that [nativeId] started ringing and describes it for the UI.
  /// Returns null when the id does not belong to a saved alarm.
  Future<RingingAlarm?> handleRing(int nativeId) => _serialized(() async {
        final alarm = await _findByNativeId(nativeId);
        if (alarm == null) return null;
        final index = _reincarnationIndex(alarm.id, nativeId);
        if (index == null) {
          return RingingAlarm(
            nativeId: nativeId,
            title: alarm.title,
            alarm: alarm,
            canSnooze: true,
          );
        }
        final run = await _reincarnationRepository.findActive(alarm.id);
        if (run == null) {
          return RingingAlarm(
              nativeId: nativeId, title: alarm.title, alarm: alarm);
        }
        final isLast = index >= run.reincarnationCount;
        await _reincarnationRepository.save(
          run.copyWith(
            remainingCount: run.reincarnationCount - index,
            nextFireAt: run.firingAt(isLast ? index : index + 1),
          ),
        );
        return RingingAlarm(
          nativeId: nativeId,
          title: alarm.title,
          alarm: alarm,
          canSnooze: !isLast,
        );
      });

  /// Snoozes a ringing alarm.
  ///
  /// The first snooze starts a reincarnation chain: one ring after the snooze
  /// duration, then [AlarmModel.reincarnationCount] more rings spaced by the
  /// reincarnation interval, all scheduled natively right away. Snoozing a
  /// ring that is already part of the chain only silences it; the next
  /// firing is already scheduled.
  Future<void> snooze(AlarmModel alarm, {int? ringingNativeId}) =>
      _serialized(() async {
        final current = await _repository.findById(alarm.id) ?? alarm;
        final now = _now();
        final run = await _reincarnationRepository.findActive(current.id);
        final isChainRing = ringingNativeId != null
            ? _reincarnationIndex(current.id, ringingNativeId) != null
            : run != null && run.hasFiringAfter(now);
        if (run != null && isChainRing && run.hasFiringAfter(now)) {
          final dueIds = [
            for (var index = 0; index <= run.reincarnationCount; index++)
              if (!run.firingAt(index).isAfter(now))
                reincarnationNativeId(current.id, index),
          ];
          await _cancelIds(dueIds);
          return;
        }

        await _cancelNative(current.id);
        final count =
            current.reincarnationCount.clamp(0, maxReincarnationCount).toInt();
        final firstFireAt = now.add(current.snoozeDuration);
        final newRun = ReincarnationRunModel(
          id: 'reincarnation-${current.id}',
          alarmId: current.id,
          originOccurrenceAt: current.nextOccurrenceAt ?? now,
          remainingCount: count,
          nextFireAt: firstFireAt,
          status: ReincarnationStatus.active,
          firstFireAt: firstFireAt,
          reincarnationCount: count,
          interval: current.reincarnationInterval,
        );
        await _reincarnationRepository.save(newRun);
        if (current.recurrence.scheduleType != AlarmScheduleType.once) {
          await _scheduleRegular(current);
        }
        await _scheduleChain(current, newRun, now);
      });

  /// Dismisses a ringing alarm: ends any snooze chain, then either moves a
  /// recurring alarm to its next occurrence or completes a one-time alarm
  /// (deleting it when [AlarmModel.deleteAfterUse] is set).
  Future<void> dismiss(AlarmModel alarm) => _serialized(() async {
        await _reincarnationRepository.cancelForAlarm(alarm.id);
        await _cancelNative(alarm.id);
        final current = await _repository.findById(alarm.id);
        if (current == null) return;
        if (current.recurrence.scheduleType == AlarmScheduleType.once) {
          await _finishOneTime(current);
        } else {
          await _scheduleRegular(current);
        }
      });

  Future<void> _reconcile(
    AlarmModel alarm, {
    required bool recovering,
  }) async {
    final scheduled = await _scheduler.scheduledIds();
    for (final id in nativeIdsFor(alarm.id).where(scheduled.contains)) {
      // The ring screen or notification owns a ringing alarm.
      if (await _scheduler.isRinging(id)) return;
    }

    final now = _now();
    final settled = recovering ? now.subtract(_ringGrace) : now;
    final occurrence = alarm.nextOccurrenceAt;
    if (alarm.isEnabled &&
        occurrence != null &&
        occurrence.isAfter(settled) &&
        !occurrence.isAfter(now)) {
      return; // Due this very moment; let the native alarm fire first.
    }

    var run = await _reincarnationRepository.findActive(alarm.id);
    if (run != null && !run.hasFiringAfter(settled)) {
      await _reincarnationRepository.save(
        run.copyWith(remainingCount: 0, status: ReincarnationStatus.completed),
      );
      run = null;
    }

    if (!alarm.isEnabled) {
      if (recovering) await _cancelNative(alarm.id);
      return;
    }

    if (alarm.recurrence.scheduleType == AlarmScheduleType.once) {
      if (alarm.recurrence.nextOccurrenceAfter(now) == null) {
        if (run == null) {
          await _finishOneTime(alarm);
        } else if (recovering) {
          await _scheduleChain(alarm, run, now);
        }
      } else if (recovering) {
        await _scheduleRegular(alarm);
      }
      return;
    }

    final isDue = occurrence == null || !occurrence.isAfter(now);
    if (recovering || isDue) await _scheduleRegular(alarm);
    if (recovering && run != null) await _scheduleChain(alarm, run, now);
  }

  /// Saves [alarm] with its next occurrence and schedules the primary and
  /// follow-up native alarms. Leaves any snooze chain untouched.
  Future<AlarmModel> _scheduleRegular(AlarmModel alarm) async {
    final next = alarm.recurrence.nextOccurrenceAfter(_now());
    final updated = next == null
        ? alarm.copyWith(clearNextOccurrenceAt: true)
        : alarm.copyWith(nextOccurrenceAt: next);
    await _repository.save(updated);
    await _cancelIds([
      primaryNativeId(updated.id),
      followUpNativeId(updated.id),
    ]);
    if (!updated.isEnabled || next == null) return updated;

    await _set(primaryNativeId(updated.id), next, updated);
    if (updated.recurrence.scheduleType != AlarmScheduleType.once) {
      final following = updated.recurrence.nextOccurrenceAfter(next);
      if (following != null) {
        await _set(followUpNativeId(updated.id), following, updated);
      }
    }
    return updated;
  }

  Future<void> _scheduleChain(
    AlarmModel alarm,
    ReincarnationRunModel run,
    DateTime now,
  ) async {
    for (var index = 0; index <= run.reincarnationCount; index++) {
      final fireAt = run.firingAt(index);
      if (!fireAt.isAfter(now)) continue;
      await _set(
        reincarnationNativeId(alarm.id, index),
        fireAt,
        alarm,
        body: index == 0
            ? 'Snoozed alarm'
            : 'Reminder $index of ${run.reincarnationCount}',
      );
    }
  }

  Future<void> _finishOneTime(AlarmModel alarm) async {
    await _cancelNative(alarm.id);
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

  Future<void> _set(
    int nativeId,
    DateTime dateTime,
    AlarmModel alarm, {
    String body = 'Alarm',
  }) async {
    if (!_scheduler.isSupported) return;
    final scheduled = await _scheduler.schedule(
      NativeAlarmRequest(
        id: nativeId,
        dateTime: dateTime,
        title: alarm.title,
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

  Future<void> _cancelNative(String alarmId) =>
      _cancelIds(nativeIdsFor(alarmId));

  Future<void> _cancelIds(Iterable<int> ids) async {
    if (!_scheduler.isSupported) return;
    final scheduled = await _scheduler.scheduledIds();
    for (final id in ids) {
      if (scheduled.contains(id)) await _scheduler.cancel(id);
    }
  }

  Future<AlarmModel?> _findByNativeId(int nativeId) async {
    for (final alarm in await _repository.getAll()) {
      if (nativeIdsFor(alarm.id).contains(nativeId)) return alarm;
    }
    return null;
  }

  int? _reincarnationIndex(String alarmId, int nativeId) {
    for (var index = 0; index <= maxReincarnationCount; index++) {
      if (reincarnationNativeId(alarmId, index) == nativeId) return index;
    }
    return null;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
