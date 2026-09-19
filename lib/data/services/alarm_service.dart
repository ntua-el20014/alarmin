import '../models/alarm_model.dart';
import '../repositories/alarm_repository.dart';
import 'alarm_scheduler.dart';

class AlarmService {
  AlarmService({
    required AlarmRepository repository,
    required AlarmScheduler scheduler,
    DateTime Function()? now,
  })  : _repository = repository,
        _scheduler = scheduler,
        _now = now ?? DateTime.now;

  final AlarmRepository _repository;
  final AlarmScheduler _scheduler;
  final DateTime Function() _now;

  Future<void> initialize() => _scheduler.initialize();

  Future<void> recover() async {
    await for (final alarms in _repository.watchAlarms()) {
      for (final alarm in alarms) {
        final updated = _withNextOccurrence(alarm);
        await _repository.save(updated);
        await _scheduleOrCancel(updated);
      }
      return;
    }
  }

  Future<void> save(AlarmModel alarm) async {
    final prepared = _withNextOccurrence(alarm);
    await _repository.save(prepared);
    await _scheduleOrCancel(prepared);
  }

  Future<void> setEnabled(AlarmModel alarm, bool isEnabled) async {
    final updated = _withNextOccurrence(
      alarm.copyWith(isEnabled: isEnabled, updatedAt: _now()),
    );
    await _repository.save(updated);
    await _scheduleOrCancel(updated);
  }

  Future<void> delete(AlarmModel alarm) async {
    await _scheduler.cancel(alarm.id);
    await _repository.delete(alarm.id);
  }

  Future<void> reschedule(AlarmModel alarm) async {
    final updated = _withNextOccurrence(alarm);
    await _repository.save(updated);
    await _scheduleOrCancel(updated);
  }

  AlarmModel _withNextOccurrence(AlarmModel alarm) {
    final nextOccurrence = alarm.recurrence.nextOccurrenceAfter(_now());
    return alarm.copyWith(nextOccurrenceAt: nextOccurrence);
  }

  Future<void> _scheduleOrCancel(AlarmModel alarm) async {
    if (!_scheduler.isSupported) {
      return;
    }
    await _scheduler.cancel(alarm.id);
    if (!alarm.isEnabled || alarm.nextOccurrenceAt == null) {
      return;
    }
    final scheduled = await _scheduler.schedule(
      alarm,
      alarm.nextOccurrenceAt!,
    );
    if (!scheduled) {
      throw StateError('Unable to schedule alarm ${alarm.id}.');
    }
  }
}
