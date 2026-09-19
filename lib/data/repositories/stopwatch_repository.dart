import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../models/stopwatch_models.dart' as domain;

class StopwatchRepository {
  StopwatchRepository(this._database);

  final db.AppDatabase _database;

  Stream<List<domain.StopwatchSession>> watchHistory() {
    return (_database.select(_database.stopwatchSessions)
          ..where((session) => session.status
              .equals(domain.StopwatchSessionStatus.completed.index))
          ..orderBy([
            (session) => OrderingTerm(
                  expression: session.startedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch()
        .map((rows) => rows.map(_toSession).toList());
  }

  Future<void> saveCompletedSession(
    domain.StopwatchSession session,
    List<domain.StopwatchLap> laps,
  ) {
    return _database.transaction(() async {
      await _database.into(_database.stopwatchSessions).insert(
            _toSessionCompanion(session),
            mode: InsertMode.insertOrReplace,
          );
      await (_database.delete(_database.stopwatchLaps)
            ..where((lap) => lap.sessionId.equals(session.id)))
          .go();
      await _database.batch((batch) {
        batch.insertAll(
          _database.stopwatchLaps,
          laps.map(_toLapCompanion).toList(),
        );
      });
    });
  }

  Future<List<domain.StopwatchLap>> lapsForSession(String sessionId) async {
    final rows = await (_database.select(_database.stopwatchLaps)
          ..where((lap) => lap.sessionId.equals(sessionId))
          ..orderBy([(lap) => OrderingTerm(expression: lap.sequence)]))
        .get();
    return rows
        .map(
          (row) => domain.StopwatchLap(
            id: row.id,
            sessionId: row.sessionId,
            sequence: row.sequence,
            elapsedAtLapMs: row.elapsedAtLapMs,
            lapDurationMs: row.lapDurationMs,
            recordedAt: row.recordedAt,
          ),
        )
        .toList();
  }

  Future<void> deleteSession(String sessionId) {
    return (_database.delete(_database.stopwatchSessions)
          ..where((session) => session.id.equals(sessionId)))
        .go();
  }

  Future<void> clearHistory() {
    return (_database.delete(_database.stopwatchSessions)
          ..where((session) => session.status
              .equals(domain.StopwatchSessionStatus.completed.index)))
        .go();
  }

  domain.StopwatchSession _toSession(db.StopwatchSession row) {
    return domain.StopwatchSession(
      id: row.id,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      totalTimeMs: row.totalTimeMs,
      status: domain.StopwatchSessionStatus.values[row.status],
      createdAt: row.createdAt,
    );
  }

  db.StopwatchSessionsCompanion _toSessionCompanion(
      domain.StopwatchSession session) {
    return db.StopwatchSessionsCompanion.insert(
      id: session.id,
      startedAt: session.startedAt,
      endedAt: Value(session.endedAt),
      totalTimeMs: session.totalTimeMs,
      status: session.status.index,
      createdAt: session.createdAt,
    );
  }

  db.StopwatchLapsCompanion _toLapCompanion(domain.StopwatchLap lap) {
    return db.StopwatchLapsCompanion.insert(
      id: lap.id,
      sessionId: lap.sessionId,
      sequence: lap.sequence,
      elapsedAtLapMs: lap.elapsedAtLapMs,
      lapDurationMs: lap.lapDurationMs,
      recordedAt: lap.recordedAt,
    );
  }
}
