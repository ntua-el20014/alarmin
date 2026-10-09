import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/ringing_alarm.dart';

/// Full-screen page shown while an alarm or the timer is ringing. It closes
/// itself when nothing is ringing any more (also when the alarm was stopped
/// from its notification).
class RingScreen extends ConsumerStatefulWidget {
  const RingScreen({super.key});

  @override
  ConsumerState<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends ConsumerState<RingScreen> {
  late final ValueNotifier<RingingAlarm?> _ringing;
  bool _busy = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ringing = ref.read(ringingAlarmProvider);
    _ringing.addListener(_closeWhenSilent);
  }

  @override
  void dispose() {
    _ringing.removeListener(_closeWhenSilent);
    super.dispose();
  }

  void _closeWhenSilent() {
    if (_ringing.value == null && !_closing && mounted) {
      _closing = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.read(alarmRingHandlerProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.primaryContainer,
        body: SafeArea(
          child: ValueListenableBuilder<RingingAlarm?>(
            valueListenable: _ringing,
            builder: (context, ringing, _) {
              if (ringing == null) return const SizedBox.shrink();
              final alarm = ringing.alarm;
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),
                    Icon(Icons.alarm, size: 96, color: colors.primary),
                    const SizedBox(height: 24),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(
                        const Duration(seconds: 1),
                        (_) => DateTime.now(),
                      ),
                      builder: (context, snapshot) => Text(
                        TimeOfDay.fromDateTime(snapshot.data ?? DateTime.now())
                            .format(context),
                        style: textTheme.displayLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ringing.title,
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    if (alarm != null && ringing.canSnooze)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() => handler.snooze(
                                    alarm,
                                    nativeId: ringing.nativeId,
                                  )),
                          icon: const Icon(Icons.snooze),
                          label: const Text('Snooze'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() => handler.stop(ringing)),
                        icon: const Icon(Icons.alarm_off),
                        label: Text(alarm == null ? 'Stop' : 'Dismiss'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
