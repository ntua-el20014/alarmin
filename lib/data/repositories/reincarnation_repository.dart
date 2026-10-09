import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/reincarnation_model.dart';

class ReincarnationRepository {
  ReincarnationRepository(this._database);

  final AppDatabase _database;

  Future<ReincarnationRunModel?> findActive(String alarmId) async {
    final rows = await (_database.select(_database.reincarnationRuns)
          ..where(
            (run) =>
                run.alarmId.equals(alarmId) &
                run.status.equals(ReincarnationStatus.active.index),
          ))
        .get();
    for (final row in rows) {
      final run = _toModel(row);
      if (run != null) return run;
    }
    return null;
  }

  Future<void> save(ReincarnationRunModel run) {
    return _database.into(_database.reincarnationRuns).insertOnConflictUpdate(
          ReincarnationRunsCompanion.insert(
            id: run.id,
            alarmId: run.alarmId,
            originOccurrenceAt: run.originOccurrenceAt,
            remainingCount: run.remainingCount,
            nextFireAt: run.nextFireAt,
            status: run.status.index,
            firstFireAt: Value(run.firstFireAt),
            chainReincarnationCount: Value(run.reincarnationCount),
            chainIntervalSeconds: Value(run.interval.inSeconds),
          ),
        );
  }

  Future<void> cancelForAlarm(String alarmId) {
    return (_database.update(_database.reincarnationRuns)
          ..where(
            (run) =>
                run.alarmId.equals(alarmId) &
                run.status.equals(ReincarnationStatus.active.index),
          ))
        .write(
      ReincarnationRunsCompanion(
        status: Value(ReincarnationStatus.cancelled.index),
      ),
    );
  }

  /// Returns null for legacy (schema v1) rows that lack chain timing; those
  /// chains were never fully scheduled and are ignored.
  ReincarnationRunModel? _toModel(ReincarnationRun row) {
    final firstFireAt = row.firstFireAt;
    final count = row.chainReincarnationCount;
    final intervalSeconds = row.chainIntervalSeconds;
    if (firstFireAt == null || count == null || intervalSeconds == null) {
      return null;
    }
    return ReincarnationRunModel(
      id: row.id,
      alarmId: row.alarmId,
      originOccurrenceAt: row.originOccurrenceAt,
      remainingCount: row.remainingCount,
      nextFireAt: row.nextFireAt,
      status: ReincarnationStatus.values[row.status],
      firstFireAt: firstFireAt,
      reincarnationCount: count,
      interval: Duration(seconds: intervalSeconds),
    );
  }
}
