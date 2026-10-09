import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/features/timer/timer_controller.dart';
import 'package:alarmin/features/timer/timer_completion_service.dart';

void main() {
  test('supports duration selection and reset', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(timerControllerProvider.notifier);

    controller.setDuration(const Duration(minutes: 2, seconds: 30));

    expect(container.read(timerControllerProvider).duration,
        const Duration(minutes: 2, seconds: 30));
    expect(container.read(timerControllerProvider).remaining,
        const Duration(minutes: 2, seconds: 30));
    expect(container.read(timerControllerProvider).status, TimerStatus.idle);
  });

  test('supports start, pause, resume, and reset without persistence', () {
    final notifier = FakeTimerCompletionNotifier();
    final container = ProviderContainer(
      overrides: [timerCompletionProvider.overrideWithValue(notifier)],
    );
    addTearDown(container.dispose);
    final controller = container.read(timerControllerProvider.notifier);
    controller.setDuration(const Duration(seconds: 10));

    controller.start();
    expect(container.read(timerControllerProvider).status, TimerStatus.running);

    controller.pause();
    expect(container.read(timerControllerProvider).status, TimerStatus.paused);

    controller.resume();
    expect(container.read(timerControllerProvider).status, TimerStatus.running);

    controller.reset();
    final state = container.read(timerControllerProvider);
    expect(state.status, TimerStatus.idle);
    expect(state.remaining, const Duration(seconds: 10));
    // Started twice, and the native alarm was cancelled on pause and reset.
    expect(notifier.scheduled, hasLength(2));
    expect(notifier.cancellations, 2);
  });

  test('schedules the native completion alarm when started', () {
    final notifier = FakeTimerCompletionNotifier();
    final container = ProviderContainer(
      overrides: [timerCompletionProvider.overrideWithValue(notifier)],
    );
    addTearDown(container.dispose);
    final controller = container.read(timerControllerProvider.notifier);

    fakeAsync((async) {
      controller.setDuration(const Duration(milliseconds: 50));
      final startedAt = clock.now();
      controller.start();
      async.elapse(const Duration(milliseconds: 180));

      expect(container.read(timerControllerProvider).status,
          TimerStatus.completed);
      expect(notifier.scheduled,
          [startedAt.add(const Duration(milliseconds: 50))]);

      // Starting a finished timer runs it again from its full duration.
      controller.start();
      expect(
          container.read(timerControllerProvider).status, TimerStatus.running);
      expect(notifier.scheduled, hasLength(2));
    });
  });
}

class FakeTimerCompletionNotifier implements TimerCompletionNotifier {
  final scheduled = <DateTime>[];
  var cancellations = 0;

  @override
  Future<void> scheduleCompletion(DateTime at) async => scheduled.add(at);

  @override
  Future<void> cancel() async => cancellations++;
}
