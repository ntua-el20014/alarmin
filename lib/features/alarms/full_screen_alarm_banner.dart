import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/services/alarm_permissions.dart';

/// Shown on the Alarms tab while alarms cannot take over the screen like the
/// Clock app does (wake the display and open over the lock screen). Hidden
/// once every permission is granted.
class FullScreenAlarmBanner extends ConsumerWidget {
  const FullScreenAlarmBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missing = ref.watch(fullScreenAlarmIssuesProvider).value ?? const [];
    if (missing.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading:
              Icon(Icons.screen_lock_portrait, color: colors.onErrorContainer),
          title: Text(
            'Alarms can\'t wake your screen',
            style: TextStyle(color: colors.onErrorContainer),
          ),
          subtitle: Text(
            'Tap to allow ${missing.length == 1 ? 'one setting' : '${missing.length} settings'}',
            style: TextStyle(color: colors.onErrorContainer),
          ),
          trailing: Icon(Icons.chevron_right, color: colors.onErrorContainer),
          onTap: () => _showFixes(context),
        ),
      ),
    );
  }

  Future<void> _showFixes(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _FixList(),
    );
  }
}

class _FixList extends ConsumerWidget {
  const _FixList();

  static const _explanations = {
    'Notifications': 'Shows the alarm and its Stop button.',
    AlarmPermissions.fullScreenLabel:
        'Android calls this "full-screen notifications". Turns the screen on '
            'and shows the alarm over the lock screen.',
    AlarmPermissions.overlayLabel:
        'Android calls this "display over other apps". Opens the alarm '
            'screen even when Android ignores the full-screen notification.',
    AlarmPermissions.lockScreenLabel:
        'Your phone adds its own setting for this. On the page that opens, '
            'allow "Show on lock screen" and "Display pop-up windows while '
            'running in the background" (or similar).',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missing = ref.watch(fullScreenAlarmIssuesProvider).value ?? const [];
    final permissions = ref.read(alarmPermissionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'To ring like the Clock app, allow:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (missing.isEmpty)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('All set'),
              ),
            for (final label in missing)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(_explanations[label] ?? ''),
                trailing: FilledButton(
                  onPressed: () async {
                    await permissions.request(label);
                    ref.invalidate(fullScreenAlarmIssuesProvider);
                  },
                  child: const Text('Allow'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
