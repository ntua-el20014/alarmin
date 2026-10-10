import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/reincarnation_model.dart';

class ReincarnationRepository {
  ReincarnationRepository(this._database);

  final AppDatabase _database;

  /// Active reminder runs of [alarmId], oldest occurrence first.
  Future<List<ReincarnationRunModel>> activeForAlarm(String alarmId) async {
    final rows = await (_database.select(_database.reincarnationRuns)
          ..where(
            (run) =>
                run.alarmId.equals(alarmId) &
                run.status.equals(ReincarnationStatus.active.index),
          )
          ..orderBy(
              [(run) => OrderingTerm(expression: run.originOccurrenceAt)]))
        .get();
    return [
      for (final row in rows)
        if (_toModel(row) case final run?) run,
    ];
  }

  Future<ReincarnationRunModel?> findById(String id) async {
    final row = await (_database.select(_database.reincarnationRuns)
          ..where((run) => run.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
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
            firstFireAt: Value(run.reminderAt(1)),
            chainReincarnationCount: Value(run.reminderCount),
            chainIntervalSeconds: Value(run.interval.inSeconds),
          ),
        );
  }

  Future<void> delete(String id) {
    return (_database.delete(_database.reincarnationRuns)
          ..where((run) => run.id.equals(id)))
        .go();
  }

  Future<void> deleteForAlarm(String alarmId) {
    return (_database.delete(_database.reincarnationRuns)
          ..where((run) => run.alarmId.equals(alarmId)))
        .go();
  }

  ReincarnationRunModel? _toModel(ReincarnationRun row) {
    final count = row.chainReincarnationCount;
    final intervalSeconds = row.chainIntervalSeconds;
    if (count == null || intervalSeconds == null) return null;
    return ReincarnationRunModel(
      id: row.id,
      alarmId: row.alarmId,
      originOccurrenceAt: row.originOccurrenceAt,
      reminderCount: count,
      interval: Duration(seconds: intervalSeconds),
      remainingCount: row.remainingCount,
      nextFireAt: row.nextFireAt,
      status: ReincarnationStatus.values[row.status],
    );
  }
}
