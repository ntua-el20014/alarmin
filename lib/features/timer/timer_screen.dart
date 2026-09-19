import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timer_controller.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final canEditDuration = timer.status != TimerStatus.running;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _formatDuration(timer.remaining),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !canEditDuration,
            child: Opacity(
              opacity: canEditDuration ? 1 : 0.45,
              child: SizedBox(
                height: 170,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: timer.duration,
                  onTimerDurationChanged: controller.setDuration,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: timer.status == TimerStatus.running
                    ? controller.pause
                    : timer.status == TimerStatus.paused
                        ? controller.resume
                        : controller.start,
                icon: Icon(
                  timer.status == TimerStatus.running
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                label: Text(
                  timer.status == TimerStatus.running
                      ? 'Pause'
                      : timer.status == TimerStatus.paused
                          ? 'Resume'
                          : 'Start',
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: controller.reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
