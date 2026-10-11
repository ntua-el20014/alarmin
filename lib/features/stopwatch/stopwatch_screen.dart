import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/stopwatch_models.dart' as domain;
import 'stopwatch_controller.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchControllerProvider);
    final controller = ref.read(stopwatchControllerProvider.notifier);
    final isRunning = state.status == domain.StopwatchSessionStatus.running;
    final hasSession = state.hasSession;
    final isPaused = hasSession && !isRunning;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatDuration(state.elapsed),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'History',
                icon: const Icon(Icons.history),
                onPressed: () => _showHistory(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.laps.isEmpty
              ? const Center(child: Text('No laps yet'))
              : ListView.builder(
                  itemCount: state.laps.length,
                  itemBuilder: (context, index) {
                    final lap = state.laps[index];
                    return ListTile(
                      leading: Text('${lap.sequence}'),
                      title: Text(_formatMilliseconds(lap.lapDurationMs)),
                      trailing: Text(_formatMilliseconds(lap.elapsedAtLapMs)),
                    );
                  },
                ),
        ),
        // Big controls at the bottom, within thumb reach. Finish and Discard
        // only exist while paused, so a running session cannot be ended by
        // accident.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPaused) ...[
                Row(
                  children: [
                    Expanded(
                      child: _BigButton(
                        label: 'Discard',
                        icon: Icons.delete_outline,
                        style: _BigButtonStyle.text,
                        onPressed: () => _confirmDiscard(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigButton(
                        label: 'Finish',
                        icon: Icons.save,
                        style: _BigButtonStyle.tonal,
                        onPressed: () => _finish(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (hasSession) ...[
                    Expanded(
                      child: _BigButton(
                        label: 'Flag',
                        icon: Icons.flag,
                        style: _BigButtonStyle.outlined,
                        onPressed: controller.flag,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _BigButton(
                      label: isRunning
                          ? 'Pause'
                          : hasSession
                              ? 'Resume'
                              : 'Start',
                      icon: isRunning ? Icons.pause : Icons.play_arrow,
                      style: _BigButtonStyle.filled,
                      onPressed:
                          isRunning ? controller.pause : controller.start,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text('The time and laps will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(stopwatchControllerProvider.notifier).reset();
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(stopwatchControllerProvider.notifier).finish();
      messenger.showSnackBar(
        const SnackBar(content: Text('Session saved to history')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the session: $error')),
      );
    }
  }

  Future<void> _showHistory(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _StopwatchHistorySheet(),
    );
  }

  String _formatDuration(Duration duration) =>
      _formatMilliseconds(duration.inMilliseconds);

  String _formatMilliseconds(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final hundredths =
        (duration.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds.$hundredths';
  }
}

class _StopwatchHistorySheet extends ConsumerWidget {
  const _StopwatchHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(stopwatchHistoryProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: history.when(
          data: (sessions) => Column(
            children: [
              ListTile(
                title: Text(
                  'History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: TextButton.icon(
                  onPressed: sessions.isEmpty
                      ? null
                      : () => _confirmClear(context, ref),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear'),
                ),
              ),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('No saved sessions'))
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return ListTile(
                            title: Text(_formatSession(session.totalTimeMs)),
                            subtitle: Text(
                              '${MaterialLocalizations.of(context).formatMediumDate(session.startedAt)}'
                              ' · '
                              '${TimeOfDay.fromDateTime(session.startedAt).format(context)}',
                            ),
                            onTap: () => _showSession(context, ref, session),
                            trailing: IconButton(
                              tooltip: 'Delete session',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(stopwatchRepositoryProvider)
                                  .deleteSession(session.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear stopwatch history?'),
        content: const Text('All saved sessions and laps will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(stopwatchRepositoryProvider).clearHistory();
    }
  }

  Future<void> _showSession(
    BuildContext context,
    WidgetRef ref,
    domain.StopwatchSession session,
  ) async {
    final laps =
        await ref.read(stopwatchRepositoryProvider).lapsForSession(session.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved laps'),
        content: SizedBox(
          width: double.maxFinite,
          child: laps.isEmpty
              ? const Text('No laps recorded')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: laps.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Lap ${laps[index].sequence}'),
                    trailing: Text(_formatSession(laps[index].lapDurationMs)),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatSession(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final hundredths =
        (duration.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0
        ? '$hours:$minutes:$seconds.$hundredths'
        : '$minutes:$seconds.$hundredths';
  }
}

enum _BigButtonStyle { filled, tonal, outlined, text }

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final _BigButtonStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(64)),
      textStyle:
          WidgetStatePropertyAll(Theme.of(context).textTheme.titleMedium),
      iconSize: const WidgetStatePropertyAll(26),
    );
    final iconWidget = Icon(icon);
    final labelWidget = Text(label);
    return switch (style) {
      _BigButtonStyle.filled => FilledButton.icon(
          style: buttonStyle,
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
        ),
      _BigButtonStyle.tonal => FilledButton.tonalIcon(
          style: buttonStyle,
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
        ),
      _BigButtonStyle.outlined => OutlinedButton.icon(
          style: buttonStyle,
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
        ),
      _BigButtonStyle.text => TextButton.icon(
          style: buttonStyle,
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
        ),
    };
  }
}
