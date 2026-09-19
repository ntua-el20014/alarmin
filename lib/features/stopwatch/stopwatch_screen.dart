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

    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          _formatDuration(state.elapsed),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: isRunning ? controller.pause : controller.start,
              icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(isRunning
                  ? 'Pause'
                  : hasSession
                      ? 'Resume'
                      : 'Start'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: hasSession ? controller.flag : null,
              icon: const Icon(Icons.flag),
              label: const Text('Flag'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: hasSession ? controller.finish : null,
              icon: const Icon(Icons.save),
              label: const Text('Finish'),
            ),
          ],
        ),
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
        TextButton.icon(
          onPressed: () => _showHistory(context),
          icon: const Icon(Icons.history),
          label: const Text('History'),
        ),
        const SizedBox(height: 12),
      ],
    );
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
          data: (sessions) => sessions.isEmpty
              ? const Center(child: Text('No saved sessions'))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      title: Text(_formatSession(session.totalTimeMs)),
                      subtitle: Text(session.startedAt.toLocal().toString()),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
      ),
    );
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
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
