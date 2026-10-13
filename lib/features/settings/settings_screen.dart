import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/links.dart';
import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category_model.dart';
import '../../data/models/ringtone.dart';
import '../../data/services/alarm_permissions.dart';
import '../../data/services/alarm_scheduler.dart';
import '../categories/category_dialog.dart';
import '../sounds/sound_picker.dart';

/// The Settings tab: a menu of categories, each opening its own page.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(fullScreenAlarmIssuesProvider).value ?? const [];
    final categoryCount = ref.watch(categoriesProvider).value?.length;

    return ListView(
      children: [
        _MenuTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme and time picker',
          page: _SettingsPage(
            title: 'Appearance',
            child: _WithSettings(
              builder: (settings) => _AppearanceSection(settings: settings),
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.alarm,
          title: 'Alarms',
          subtitle: 'Vibration, snooze and upcoming alarm notice',
          page: _SettingsPage(
            title: 'Alarms',
            child: _WithSettings(
              builder: (settings) => _AlarmDefaultsSection(settings: settings),
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.music_note_outlined,
          title: 'Sounds',
          subtitle: 'Default alarm sound and timer sound',
          page: _SettingsPage(
            title: 'Sounds',
            child: _WithSettings(
              builder: (settings) => _SoundsSection(settings: settings),
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.label_outline,
          title: 'Categories',
          subtitle: switch (categoryCount) {
            null => 'Group alarms with an emoji',
            1 => '1 category',
            final count => '$count categories',
          },
          page: const _SettingsPage(
            title: 'Categories',
            child: _CategoriesPage(),
          ),
        ),
        _MenuTile(
          icon: issues.isEmpty
              ? Icons.verified_user_outlined
              : Icons.warning_amber_rounded,
          iconColor:
              issues.isEmpty ? null : Theme.of(context).colorScheme.error,
          title: 'Permissions and test',
          subtitle: switch (issues.length) {
            0 => 'Check that alarms ring and wake the screen',
            1 => '1 setting needs attention',
            final count => '$count settings need attention',
          },
          page: const _SettingsPage(
            title: 'Permissions and test',
            child: _ReliabilitySection(),
          ),
        ),
        const _MenuTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Privacy policy and licenses',
          page: _SettingsPage(title: 'About', child: _AboutSection()),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [child],
      ),
    );
  }
}

/// Builds a section from the saved settings once they are loaded.
class _WithSettings extends ConsumerWidget {
  const _WithSettings({required this.builder});

  final Widget Function(AppSettings settings) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(settingsProvider).when(
          data: builder,
          loading: () => const _Loading(),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
}

Future<void> _saveSettings(WidgetRef ref, AppSettings value) {
  return ref.read(settingsRepositoryProvider).save(value);
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          subtitle: const Text('No data leaves your device'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (!await openUrl(privacyPolicyUrl)) {
              messenger.showSnackBar(
                const SnackBar(content: Text('No browser found')),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Alarmin',
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onChanged: (dark) => _saveSettings(
            ref,
            settings.copyWith(
              themeMode: dark ? AppThemeMode.dark : AppThemeMode.light,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
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
                _saveSettings(ref, settings.copyWith(timePickerStyle: style));
              }
            },
          ),
        ),
      ],
    );
  }
}

class _AlarmDefaultsSection extends ConsumerWidget {
  const _AlarmDefaultsSection({required this.settings});

  static const _snoozeOptions = [1, 3, 5, 10, 15, 20, 30];

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snoozeMinutes = settings.defaultSnoozeDuration.inMinutes;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: const Text('Vibrate by default'),
          subtitle: const Text('For new alarms'),
          value: settings.defaultVibration != VibrationSetting.off,
          onChanged: (value) => _saveSettings(
            ref,
            settings.copyWith(
              defaultVibration:
                  value ? VibrationSetting.standard : VibrationSetting.off,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.snooze),
          title: const Text('Default snooze'),
          subtitle: const Text('For new alarms'),
          trailing: DropdownButton<int>(
            value: _snoozeOptions.contains(snoozeMinutes) ? snoozeMinutes : 10,
            items: [
              for (final minutes in _snoozeOptions)
                DropdownMenuItem(value: minutes, child: Text('$minutes min')),
            ],
            onChanged: (value) {
              if (value != null) {
                _saveSettings(
                  ref,
                  settings.copyWith(
                    defaultSnoozeDuration: Duration(minutes: value),
                  ),
                );
              }
            },
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_none),
          title: const Text('Notify 1 hour before alarms'),
          subtitle: const Text('A silent notification with a Skip button'),
          value: settings.upcomingAlarmNotice,
          onChanged: (value) async {
            await _saveSettings(
                ref, settings.copyWith(upcomingAlarmNotice: value));
            // Shows or removes the notifications of every alarm.
            await ref.read(alarmServiceProvider).recover();
          },
        ),
      ],
    );
  }
}

class _SoundsSection extends ConsumerWidget {
  const _SoundsSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SoundPicker(
            label: 'Default alarm sound',
            value: settings.defaultRingtone,
            onChanged: (value) async {
              await _saveSettings(
                ref,
                settings.copyWith(
                  defaultRingtone: value ?? Ringtone.fallbackId,
                ),
              );
              // Alarms set to "Default" pick up the new sound.
              await ref.read(alarmServiceProvider).recover();
            },
          ),
          const SizedBox(height: 16),
          SoundPicker(
            label: 'Timer sound',
            noneLabel: 'Same as default alarm sound',
            value: settings.timerRingtone,
            onChanged: (value) => _saveSettings(
              ref,
              value == null
                  ? settings.copyWith(clearTimerRingtone: true)
                  : settings.copyWith(timerRingtone: value),
            ),
          ),
        ],
      ),
    );
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
    if (!mounted) return;
    setState(() => _status = status);
    // Keeps the warning on the Settings menu in step.
    ref.invalidate(fullScreenAlarmIssuesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.read(alarmPermissionsProvider);
    final scheduler = ref.read(alarmSchedulerProvider);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Check these if an alarm does not ring or does not show over '
            'the lock screen. Tap a setting that is not allowed to fix it.',
          ),
        ),
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
            // The lock screen setting may not be readable back, so its page
            // stays one tap away.
            onTap: entry.value && entry.key != AlarmPermissions.lockScreenLabel
                ? null
                : () async {
                    await permissions.request(entry.key);
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

class _CategoriesPage extends ConsumerWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(categoriesProvider).when(
          data: (items) => _CategorySection(categories: items),
          loading: () => const _Loading(),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        );
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
  ]) {
    return showCategoryEditor(context, ref, category: category);
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
