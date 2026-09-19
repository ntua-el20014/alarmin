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

  test('signals completion once when the countdown reaches zero', () {
    final notifier = FakeTimerCompletionNotifier();
    final container = ProviderContainer(
      overrides: [timerCompletionProvider.overrideWithValue(notifier)],
    );
    addTearDown(container.dispose);
    final controller = container.read(timerControllerProvider.notifier);

    fakeAsync((async) {
      controller.setDuration(const Duration(milliseconds: 50));
      controller.start();
      async.elapse(const Duration(milliseconds: 180));

      expect(container.read(timerControllerProvider).status,
          TimerStatus.completed);
      expect(notifier.notifications, 1);
    });
  });
}

class FakeTimerCompletionNotifier implements TimerCompletionNotifier {
  var notifications = 0;

  @override
  Future<void> notify() async => notifications++;
}
