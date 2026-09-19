enum StopwatchSessionStatus { running, paused, completed, discarded }

class StopwatchSession {
  const StopwatchSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.totalTimeMs,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalTimeMs;
  final StopwatchSessionStatus status;
  final DateTime createdAt;
}

class StopwatchLap {
  const StopwatchLap({
    required this.id,
    required this.sessionId,
    required this.sequence,
    required this.elapsedAtLapMs,
    required this.lapDurationMs,
    required this.recordedAt,
  });

  final String id;
  final String sessionId;
  final int sequence;
  final int elapsedAtLapMs;
  final int lapDurationMs;
  final DateTime recordedAt;
}
