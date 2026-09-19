import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/stopwatch_models.dart' as domain;

class StopwatchState {
  const StopwatchState({
    required this.status,
    required this.elapsed,
    required this.laps,
    this.startedAt,
  });

  const StopwatchState.initial()
      : status = domain.StopwatchSessionStatus.discarded,
        elapsed = Duration.zero,
        laps = const [],
        startedAt = null;

  final domain.StopwatchSessionStatus status;
  final Duration elapsed;
  final List<domain.StopwatchLap> laps;
  final DateTime? startedAt;

  bool get hasSession => startedAt != null;

  StopwatchState copyWith({
    domain.StopwatchSessionStatus? status,
    Duration? elapsed,
    List<domain.StopwatchLap>? laps,
    DateTime? startedAt,
    bool clearStartedAt = false,
  }) {
    return StopwatchState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      laps: laps ?? this.laps,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
    );
  }
}

class StopwatchController extends Notifier<StopwatchState> {
  Stopwatch? _stopwatch;
  Timer? _ticker;
  Duration _elapsedBeforeStart = Duration.zero;

  @override
  StopwatchState build() {
    ref.onDispose(_stopTicker);
    return const StopwatchState.initial();
  }

  void start() {
    if (state.status == domain.StopwatchSessionStatus.running) return;
    if (!state.hasSession) {
      state = state.copyWith(
        status: domain.StopwatchSessionStatus.running,
        startedAt: DateTime.now(),
      );
      _elapsedBeforeStart = Duration.zero;
    } else {
      state = state.copyWith(status: domain.StopwatchSessionStatus.running);
    }
    _stopwatch ??= Stopwatch();
    _stopwatch!.reset();
    _stopwatch!.start();
    _startTicker();
  }

  void pause() {
    if (state.status != domain.StopwatchSessionStatus.running) return;
    _updateElapsed();
    _stopwatch?.stop();
    _elapsedBeforeStart = state.elapsed;
    _stopTicker();
    state = state.copyWith(status: domain.StopwatchSessionStatus.paused);
  }

  void resume() => start();

  void flag() {
    if (!state.hasSession) return;
    _updateElapsed();
    final previous = state.laps.isEmpty
        ? Duration.zero
        : state.laps.last.elapsedAtLapMs.toDuration();
    final lap = domain.StopwatchLap(
      id: 'lap-${DateTime.now().microsecondsSinceEpoch}',
      sessionId: _sessionId,
      sequence: state.laps.length + 1,
      elapsedAtLapMs: state.elapsed.inMilliseconds,
      lapDurationMs: state.elapsed.inMilliseconds - previous.inMilliseconds,
      recordedAt: DateTime.now(),
    );
    state = state.copyWith(laps: [...state.laps, lap]);
  }

  Future<void> finish() async {
    if (!state.hasSession) return;
    _updateElapsed();
    _stopwatch?.stop();
    _stopTicker();
    final session = domain.StopwatchSession(
      id: _sessionId,
      startedAt: state.startedAt!,
      endedAt: DateTime.now(),
      totalTimeMs: state.elapsed.inMilliseconds,
      status: domain.StopwatchSessionStatus.completed,
      createdAt: state.startedAt!,
    );
    await ref.read(stopwatchRepositoryProvider).saveCompletedSession(
          session,
          state.laps,
        );
    _resetState();
  }

  void reset() {
    _stopTicker();
    _stopwatch?.stop();
    _resetState();
  }

  String get _sessionId => state.startedAt == null
      ? 'session-${DateTime.now().microsecondsSinceEpoch}'
      : 'session-${state.startedAt!.microsecondsSinceEpoch}';

  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateElapsed(),
    );
  }

  void _updateElapsed() {
    final stopwatch = _stopwatch;
    if (stopwatch == null) return;
    state = state.copyWith(
      elapsed: _elapsedBeforeStart + stopwatch.elapsed,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _resetState() {
    _stopwatch = null;
    _elapsedBeforeStart = Duration.zero;
    state = const StopwatchState.initial();
  }
}

extension on int {
  Duration toDuration() => Duration(milliseconds: this);
}

final stopwatchControllerProvider =
    NotifierProvider<StopwatchController, StopwatchState>(
  StopwatchController.new,
);
