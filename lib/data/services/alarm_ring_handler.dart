import 'dart:async';

import '../models/alarm_model.dart';
import '../models/reincarnation_model.dart';
import '../models/recurrence_rule.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/reincarnation_repository.dart';
import 'alarm_scheduler.dart';
import 'alarm_service.dart';

class AlarmRingHandler {
  AlarmRingHandler({
    required AlarmRepository alarmRepository,
    required ReincarnationRepository reincarnationRepository,
    required AlarmService alarmService,
    required AlarmScheduler scheduler,
    DateTime Function()? now,
  })  : _alarmRepository = alarmRepository,
        _reincarnationRepository = reincarnationRepository,
        _alarmService = alarmService,
        _scheduler = scheduler,
        _now = now ?? DateTime.now;

  final AlarmRepository _alarmRepository;
  final ReincarnationRepository _reincarnationRepository;
  final AlarmService _alarmService;
  final AlarmScheduler _scheduler;
  final DateTime Function() _now;

  StreamSubscription<int>? _subscription;

  void start() {
    _subscription ??= _scheduler.ringEvents.listen(handleNativeRing);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> handleNativeRing(int nativeId) async {
    final alarm = await _findByNativeId(nativeId);
    if (alarm == null) return;
    final activeRun = await _reincarnationRepository.findActive(alarm.id);
    if (activeRun != null) {
      await _advanceReincarnation(alarm, activeRun);
    }
  }

  Future<void> snooze(AlarmModel alarm) async {
    final now = _now();
    final activeRun = await _reincarnationRepository.findActive(alarm.id);
    if (activeRun != null) return;

    await _scheduler.cancel(alarm.id);
    final nextFireAt = now.add(alarm.snoozeDuration);
    final run = ReincarnationRunModel(
      id: 'reincarnation-${alarm.id}',
      alarmId: alarm.id,
      originOccurrenceAt: alarm.nextOccurrenceAt ?? now,
      remainingCount: alarm.reincarnationCount,
      nextFireAt: nextFireAt,
      status: ReincarnationStatus.active,
    );
    await _reincarnationRepository.save(run);
    await _scheduler.schedule(alarm, nextFireAt);
  }

  Future<void> dismiss(AlarmModel alarm) async {
    await _scheduler.cancel(alarm.id);
    await _reincarnationRepository.cancelForAlarm(alarm.id);

    if (alarm.recurrence.scheduleType == AlarmScheduleType.once) {
      if (alarm.deleteAfterUse) {
        await _alarmService.delete(alarm);
      } else {
        await _alarmService.setEnabled(alarm, false);
      }
      return;
    }

    await _alarmService.reschedule(alarm);
  }

  Future<void> _advanceReincarnation(
    AlarmModel alarm,
    ReincarnationRunModel run,
  ) async {
    await _scheduler.cancel(alarm.id);
    if (run.remainingCount <= 0) {
      await _reincarnationRepository.save(
        ReincarnationRunModel(
          id: run.id,
          alarmId: run.alarmId,
          originOccurrenceAt: run.originOccurrenceAt,
          remainingCount: 0,
          nextFireAt: run.nextFireAt,
          status: ReincarnationStatus.completed,
        ),
      );
      return;
    }

    final nextFireAt = _now().add(alarm.reincarnationInterval);
    await _reincarnationRepository.save(
      ReincarnationRunModel(
        id: run.id,
        alarmId: run.alarmId,
        originOccurrenceAt: run.originOccurrenceAt,
        remainingCount: run.remainingCount - 1,
        nextFireAt: nextFireAt,
        status: ReincarnationStatus.active,
      ),
    );
    await _scheduler.schedule(alarm, nextFireAt);
  }

  Future<AlarmModel?> _findByNativeId(int nativeId) async {
    await for (final alarms in _alarmRepository.watchAlarms()) {
      for (final alarm in alarms) {
        if (nativeAlarmId(alarm.id) == nativeId) return alarm;
      }
      return null;
    }
    return null;
  }
}
