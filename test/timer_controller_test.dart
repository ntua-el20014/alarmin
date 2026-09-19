import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/features/timer/timer_controller.dart';

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
    final container = ProviderContainer();
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
  });
}
