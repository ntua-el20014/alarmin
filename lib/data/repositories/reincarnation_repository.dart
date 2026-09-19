import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/reincarnation_model.dart';

class ReincarnationRepository {
  ReincarnationRepository(this._database);

  final AppDatabase _database;

  Future<ReincarnationRunModel?> findActive(String alarmId) async {
    final row = await (_database.select(_database.reincarnationRuns)
          ..where(
            (run) =>
                run.alarmId.equals(alarmId) &
                run.status.equals(ReincarnationStatus.active.index),
          ))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<void> save(ReincarnationRunModel run) {
    return _database.into(_database.reincarnationRuns).insert(
          ReincarnationRunsCompanion.insert(
            id: run.id,
            alarmId: run.alarmId,
            originOccurrenceAt: run.originOccurrenceAt,
            remainingCount: run.remainingCount,
            nextFireAt: run.nextFireAt,
            status: run.status.index,
          ),
          mode: InsertMode.insertOrReplace,
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

  ReincarnationRunModel _toModel(ReincarnationRun row) {
    return ReincarnationRunModel(
      id: row.id,
      alarmId: row.alarmId,
      originOccurrenceAt: row.originOccurrenceAt,
      remainingCount: row.remainingCount,
      nextFireAt: row.nextFireAt,
      status: ReincarnationStatus.values[row.status],
    );
  }
}
