import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimerStatus { idle, running, paused, completed }

class TimerState {
  const TimerState({
    required this.duration,
    required this.remaining,
    required this.status,
  });

  const TimerState.initial()
      : duration = const Duration(minutes: 5),
        remaining = const Duration(minutes: 5),
        status = TimerStatus.idle;

  final Duration duration;
  final Duration remaining;
  final TimerStatus status;

  TimerState copyWith({
    Duration? duration,
    Duration? remaining,
    TimerStatus? status,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
    );
  }
}

class TimerController extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _remainingAtStart = Duration.zero;

  @override
  TimerState build() {
    ref.onDispose(_stopTicker);
    return const TimerState.initial();
  }

  void setDuration(Duration duration) {
    if (state.status == TimerStatus.running || duration.isNegative) return;
    state = TimerState(
      duration: duration,
      remaining: duration,
      status: TimerStatus.idle,
    );
  }

  void start() {
    if (state.remaining <= Duration.zero) return;
    _remainingAtStart = state.remaining;
    _startedAt = DateTime.now();
    _stopTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    state = state.copyWith(status: TimerStatus.running);
  }

  void pause() {
    if (state.status != TimerStatus.running) return;
    _updateRemaining();
    _stopTicker();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() {
    if (state.status == TimerStatus.paused) start();
  }

  void reset() {
    _stopTicker();
    state = state.copyWith(
      remaining: state.duration,
      status: TimerStatus.idle,
    );
  }

  void _tick() {
    _updateRemaining();
    if (state.remaining <= Duration.zero) {
      _stopTicker();
      state = state.copyWith(
        remaining: Duration.zero,
        status: TimerStatus.completed,
      );
    }
  }

  void _updateRemaining() {
    if (_startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!);
    final remaining = _remainingAtStart - elapsed;
    state = state.copyWith(
      remaining: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
  }
}

final timerControllerProvider =
    NotifierProvider<TimerController, TimerState>(TimerController.new);
