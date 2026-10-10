import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category_model.dart';
import '../../data/models/ringtone.dart';
import '../../data/services/alarm_permissions.dart';
import '../../data/services/alarm_scheduler.dart';
import 'emoji_input.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);

    return ListView(
      children: [
        settings.when(
          data: (value) => _SettingsSection(settings: value),
          loading: () => const ListTile(
            title: Text('Loading settings...'),
            leading: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        ),
        const Divider(),
        const _SectionTitle('Alarm reliability'),
        const _ReliabilitySection(),
        const Divider(),
        const _SectionTitle('Categories'),
        categories.when(
          data: (items) => _CategorySection(categories: items),
          loading: () => const ListTile(title: Text('Loading categories...')),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.settings});

  static const _snoozeOptions = [1, 3, 5, 10, 15, 20, 30];

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snoozeMinutes = settings.defaultSnoozeDuration.inMinutes;
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Dark theme'),
          secondary: Icon(
            settings.themeMode == AppThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          value: settings.themeMode == AppThemeMode.dark,
          onChanged: (dark) => _save(
            ref,
            settings.copyWith(
              themeMode: dark ? AppThemeMode.dark : AppThemeMode.light,
            ),
          ),
        ),
        ListTile(
          title: const Text('Time picker'),
          trailing: DropdownButton<TimePickerStyle>(
            value: settings.timePickerStyle,
            items: const [
              DropdownMenuItem(
                value: TimePickerStyle.materialClock,
                child: Text('Clock'),
              ),
              DropdownMenuItem(
                value: TimePickerStyle.cupertinoWheel,
                child: Text('Wheel'),
              ),
            ],
            onChanged: (style) {
              if (style != null) {
                _save(ref, settings.copyWith(timePickerStyle: style));
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Grouped alarms'),
          subtitle: const Text('Group alarms by category by default'),
          value: settings.isGroupedView,
          onChanged: (value) =>
              _save(ref, settings.copyWith(isGroupedView: value)),
        ),
        ListTile(
          title: const Text('Default ringtone'),
          subtitle: const Text('Also used by the timer'),
          trailing: DropdownButton<String>(
            value: Ringtone.resolve(settings.defaultRingtone).id,
            items: [
              for (final ringtone in Ringtone.all)
                DropdownMenuItem(
                  value: ringtone.id,
                  child: Text(ringtone.label),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                _save(ref, settings.copyWith(defaultRingtone: value));
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Vibrate by default'),
          value: settings.defaultVibration != VibrationSetting.off,
          onChanged: (value) => _save(
            ref,
            settings.copyWith(
              defaultVibration:
                  value ? VibrationSetting.standard : VibrationSetting.off,
            ),
          ),
        ),
        ListTile(
          title: const Text('Default snooze'),
          trailing: DropdownButton<int>(
            value: _snoozeOptions.contains(snoozeMinutes) ? snoozeMinutes : 10,
            items: [
              for (final minutes in _snoozeOptions)
                DropdownMenuItem(value: minutes, child: Text('$minutes min')),
            ],
            onChanged: (value) {
              if (value != null) {
                _save(
                  ref,
                  settings.copyWith(
                    defaultSnoozeDuration: Duration(minutes: value),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _save(WidgetRef ref, AppSettings value) {
    return ref.read(settingsRepositoryProvider).save(value);
  }
}

/// Permission status plus a test alarm, so a silent device can be diagnosed
/// without waiting for a real alarm.
class _ReliabilitySection extends ConsumerStatefulWidget {
  const _ReliabilitySection();

  @override
  ConsumerState<_ReliabilitySection> createState() =>
      _ReliabilitySectionState();
}

class _ReliabilitySectionState extends ConsumerState<_ReliabilitySection>
    with WidgetsBindingObserver {
  Map<String, bool> _status = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the system settings page.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await ref.read(alarmPermissionsProvider).status();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.read(alarmPermissionsProvider);
    final scheduler = ref.read(alarmSchedulerProvider);
    return Column(
      children: [
        for (final entry in _status.entries)
          ListTile(
            leading: Icon(
              entry.value ? Icons.check_circle : Icons.error_outline,
              color: entry.value
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(entry.key),
            subtitle: Text(entry.value ? 'Allowed' : 'Not allowed'),
            onTap: entry.value
                ? null
                : () async {
                    if (entry.key == AlarmPermissions.batteryLabel) {
                      await permissions.requestBatteryOptimizationExemption();
                    } else if (entry.key == AlarmPermissions.fullScreenLabel) {
                      await permissions.openWakeScreenSettings();
                    } else {
                      await permissions.openSystemSettings();
                    }
                    await _refresh();
                  },
          ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Ring a test alarm'),
          subtitle: Text(
            scheduler.isSupported
                ? 'Rings in 5 seconds; lock the screen to test'
                : 'Alarms only ring on Android and iOS',
          ),
          enabled: scheduler.isSupported,
          onTap: () => _ringTestAlarm(context),
        ),
      ],
    );
  }

  Future<void> _ringTestAlarm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final categories = ref.read(categoriesProvider).value ?? const [];
    // Ask which category to preview, so its emoji and colors can be checked.
    final choice = await showModalBottomSheet<(String?,)>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Preview which category?')),
            ListTile(
              leading: const Text('⏰', style: TextStyle(fontSize: 24)),
              title: const Text('No category'),
              onTap: () => Navigator.pop(context, (null,)),
            ),
            for (final category in categories)
              ListTile(
                leading:
                    Text(category.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(category.name),
                onTap: () => Navigator.pop(context, (category.id,)),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    ref.read(testAlarmCategoryProvider).value = choice.$1;
    final ringtone = ref.read(settingsProvider).value?.defaultRingtone ??
        Ringtone.fallbackId;
    try {
      final scheduled = await ref.read(alarmSchedulerProvider).schedule(
            NativeAlarmRequest(
              id: testAlarmNativeId,
              dateTime: DateTime.now().add(const Duration(seconds: 5)),
              title: 'Test alarm',
              body: 'Alarmin can ring on this device.',
              ringtone: ringtone,
            ),
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            scheduled
                ? 'Test alarm set for 5 seconds from now.'
                : 'The system refused the test alarm.',
          ),
        ),
      );
    } catch (error) {
      messenger
          .showSnackBar(SnackBar(content: Text('Test alarm failed: $error')));
    }
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final category in categories)
          ListTile(
            leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(category.name),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Edit category',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCategory(context, ref, category),
                ),
                IconButton(
                  tooltip: 'Delete category',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteCategory(context, ref, category),
                ),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add category'),
          onTap: () => _editCategory(context, ref),
        ),
      ],
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref, [
    CategoryModel? category,
  ]) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
    if (result == null) return;
    final now = DateTime.now();
    await ref.read(categoryRepositoryProvider).save(
          CategoryModel(
            id: category?.id ?? 'category-${now.microsecondsSinceEpoch}',
            name: result.$1,
            emoji: result.$2,
            createdAt: category?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    // Scheduled notifications show the category emoji in their title.
    if (category != null && category.emoji != result.$2) {
      await ref.read(alarmServiceProvider).recover();
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content:
            const Text('Alarms in this category will become uncategorized.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    }
  }
}

/// Owns its text controllers so they are disposed only after the dialog's
/// closing animation, not while its fields are still on screen.
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final CategoryModel? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.category?.name ?? '');
  late final TextEditingController _emoji =
      TextEditingController(text: widget.category?.emoji ?? '🏷️');

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

  String? _error;

  void _submit() {
    final name = _name.text.trim();
    final emoji = _emoji.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (!isSingleEmoji(emoji)) {
      setState(() => _error = 'Pick one emoji.');
      return;
    }
    Navigator.pop(context, (name, emoji));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emoji,
              inputFormatters: [SingleEmojiFormatter()],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32),
              decoration: const InputDecoration(
                labelText: 'Emoji',
                helperText: 'One emoji, from your emoji keyboard or below',
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final emoji in suggestedCategoryEmoji)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _emoji.text = emoji;
                      _error = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
