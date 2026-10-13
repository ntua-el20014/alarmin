import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category_model.dart';
import '../../data/models/mission.dart';
import '../../data/models/recurrence_rule.dart';
import '../../data/models/ringtone.dart';
import '../../data/services/alarm_service.dart';
import '../categories/category_dialog.dart';
import '../missions/mission_picker.dart';
import '../sounds/sound_picker.dart';
import 'alarm_labels.dart';
import 'full_screen_alarm_banner.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);

    return settings.when(
      data: (appSettings) => alarms.when(
        data: (items) => categories.when(
          data: (categoryItems) => _AlarmList(
            alarms: items,
            categories: categoryItems,
            settings: appSettings,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorMessage(error: error),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorMessage(error: error),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorMessage(error: error),
    );
  }
}

Future<void> showAlarmEditor(
  BuildContext context, {
  AlarmModel? alarm,
  bool duplicate = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AlarmEditor(alarm: alarm, duplicate: duplicate),
  );
}

class _AlarmList extends ConsumerWidget {
  const _AlarmList({
    required this.alarms,
    required this.categories,
    required this.settings,
  });

  final List<AlarmModel> alarms;
  final List<CategoryModel> categories;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final sorted = [...alarms]..sort(_compareAlarms);

    return Stack(
      children: [
        Column(
          children: [
            const FullScreenAlarmBanner(),
            Expanded(
              child: sorted.isEmpty
                  ? const Center(child: Text('No alarms yet'))
                  : settings.isGroupedView
                      ? _GroupedAlarmList(
                          alarms: sorted,
                          categories: categories,
                          categoryById: categoryById,
                        )
                      : _FlatAlarmList(
                          alarms: sorted,
                          categoryById: categoryById,
                        ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => showAlarmEditor(context),
            tooltip: 'Add alarm',
            child: const Icon(Icons.add_alarm),
          ),
        ),
      ],
    );
  }
}

class _FlatAlarmList extends StatelessWidget {
  const _FlatAlarmList({required this.alarms, required this.categoryById});

  final List<AlarmModel> alarms;
  final Map<String, CategoryModel> categoryById;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: alarms.length,
      itemBuilder: (context, index) => _AlarmTile(
        alarm: alarms[index],
        category: categoryById[alarms[index].categoryId],
      ),
    );
  }
}

class _GroupedAlarmList extends StatelessWidget {
  const _GroupedAlarmList({
    required this.alarms,
    required this.categories,
    required this.categoryById,
  });

  final List<AlarmModel> alarms;
  final List<CategoryModel> categories;
  final Map<String, CategoryModel> categoryById;

  @override
  Widget build(BuildContext context) {
    final grouped = <String?, List<AlarmModel>>{};
    for (final alarm in alarms) {
      final key =
          categoryById.containsKey(alarm.categoryId) ? alarm.categoryId : null;
      grouped.putIfAbsent(key, () => []).add(alarm);
    }
    // Categories in name order, uncategorized last.
    final keys = <String?>[
      for (final category in categories)
        if (grouped.containsKey(category.id)) category.id,
      if (grouped.containsKey(null)) null,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final key in keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              key == null
                  ? 'Uncategorized'
                  : '${categoryById[key]!.emoji} ${categoryById[key]!.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final alarm in grouped[key]!)
            // The group header already shows the category's emoji.
            _AlarmTile(
              alarm: alarm,
              category: categoryById[alarm.categoryId],
              showEmoji: false,
            ),
        ],
      ],
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({
    required this.alarm,
    required this.category,
    this.showEmoji = true,
  });

  final AlarmModel alarm;
  final CategoryModel? category;
  final bool showEmoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = !alarm.isEnabled;
    return ListTile(
      leading: showEmoji
          ? Text(category?.emoji ?? '⏰', style: const TextStyle(fontSize: 24))
          : null,
      title: Text(
        formatTimeOfDayMinutes(context, alarm.recurrence.timeOfDay),
        style: theme.textTheme.headlineSmall?.copyWith(
          color: muted ? theme.disabledColor : null,
        ),
      ),
      subtitle: Text(
        '${alarm.title} · ${describeRecurrence(alarm.recurrence)}\n'
        '${describeNextOccurrence(alarm)}'
        '${alarm.reincarnationCount > 0 ? ' · +${alarm.reincarnationCount} '
            'every ${alarm.reincarnationInterval.inMinutes} min' : ''}',
      ),
      isThreeLine: true,
      onTap: () => showAlarmEditor(context, alarm: alarm),
      onLongPress: () => _showActions(context, ref),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: (enabled) {
          final expired = enabled &&
              alarm.recurrence.nextOccurrenceAfter(DateTime.now()) == null;
          if (expired) {
            // Nothing left to schedule; let the user pick a new date.
            showAlarmEditor(context, alarm: alarm);
            return;
          }
          _run(
            context,
            () => ref.read(alarmServiceProvider).setEnabled(alarm, enabled),
          );
        },
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () => Navigator.pop(context, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'edit':
        await showAlarmEditor(context, alarm: alarm);
      case 'duplicate':
        await showAlarmEditor(context, alarm: alarm, duplicate: true);
      case 'delete':
        await _run(
          context,
          () => ref.read(alarmServiceProvider).delete(alarm),
        );
    }
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _AlarmEditor extends ConsumerStatefulWidget {
  const _AlarmEditor({this.alarm, this.duplicate = false});

  final AlarmModel? alarm;
  final bool duplicate;

  @override
  ConsumerState<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends ConsumerState<_AlarmEditor> {
  static const _snoozeOptions = [1, 3, 5, 10, 15, 20, 30];
  static const _intervalOptions = [1, 2, 3, 5, 10, 15, 20, 30];

  late final TextEditingController _titleController;
  late final TextEditingController _intervalController;
  late AlarmScheduleType _scheduleType;
  late TimeOfDay _time;
  late DateTime _date;
  late DateTime _startDate;
  late Set<int> _weekdays;
  String? _categoryId;
  late bool _isEnabled;
  late bool _deleteAfterUse;
  late String _ringtone;
  late VibrationSetting _vibration;
  late WakeStyle _wakeStyle;
  late Mission _mission;
  late int _snoozeMinutes;

  /// Fields picked by hand; a category's defaults leave them alone.
  bool _ringtoneTouched = false;
  bool _vibrationTouched = false;
  bool _wakeStyleTouched = false;
  bool _missionTouched = false;
  late int _reincarnationCount;
  late int _reincarnationIntervalMinutes;
  bool _saving = false;
  String? _error;
  int _categoryFieldVersion = 0;

  static const _newCategoryValue = '__new_category__';

  bool get _isEditing => widget.alarm != null && !widget.duplicate;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings.defaults();
    final now = DateTime.now();
    final recurrence = alarm?.recurrence;

    _titleController = TextEditingController(
      text: alarm == null
          ? ''
          : widget.duplicate
              ? '${alarm.title} (copy)'
              : alarm.title,
    );
    _scheduleType = recurrence?.scheduleType ?? AlarmScheduleType.daily;
    _time = recurrence == null
        ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1)))
        : TimeOfDay(
            hour: recurrence.timeOfDay ~/ 60,
            minute: recurrence.timeOfDay % 60,
          );
    _date = _dateOnly(recurrence?.scheduledDate ?? now);
    _startDate = _dateOnly(recurrence?.scheduleStartDate ?? now);
    _intervalController =
        TextEditingController(text: '${recurrence?.intervalDays ?? 2}');
    _weekdays = {...?recurrence?.daysOfWeek};
    _categoryId = alarm?.categoryId;
    _isEnabled = alarm?.isEnabled ?? true;
    _deleteAfterUse = alarm?.deleteAfterUse ?? false;
    // New alarms follow the Settings default until a sound is picked.
    _ringtone = alarm?.ringtone ?? Ringtone.followDefault;
    _vibration = alarm?.vibration ?? settings.defaultVibration;
    _wakeStyle = alarm?.wakeStyle ?? settings.defaultWakeStyle;
    _mission = alarm?.mission ?? const Mission.none();
    _snoozeMinutes = _nearest(
      (alarm?.snoozeDuration ?? settings.defaultSnoozeDuration).inMinutes,
      _snoozeOptions,
    );
    _reincarnationCount = (alarm?.reincarnationCount ?? 0)
        .clamp(0, maxReincarnationCount)
        .toInt();
    _reincarnationIntervalMinutes = _nearest(
      (alarm?.reincarnationInterval ?? const Duration(minutes: 5)).inMinutes,
      _intervalOptions,
    );
    // A re-enabled or duplicated one-time alarm whose date has passed starts
    // from the next possible day instead.
    if (_scheduleType == AlarmScheduleType.once &&
        _onceDateTime().isBefore(now)) {
      _date = _nextDateFor(_time);
      _isEnabled = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultSound = ref.watch(settingsProvider).value?.defaultRingtone;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final knownCategory =
        categories.any((category) => category.id == _categoryId);
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEditing)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Delete alarm',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving ? null : _delete,
                ),
              ),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Alarm',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              // Re-created when the selection changes from outside (a new
              // category), since the field only reads its initial value.
              key: ValueKey(
                  'category-$_categoryId-$knownCategory-$_categoryFieldVersion'),
              initialValue: knownCategory ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('None')),
                ...categories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text('${category.emoji} ${category.name}'),
                  ),
                ),
                const DropdownMenuItem<String?>(
                  value: _newCategoryValue,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text('New category…'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == _newCategoryValue) {
                  _createCategory();
                } else {
                  setState(() {
                    _categoryId = value;
                    _applyCategoryDefaults();
                  });
                }
              },
            ),
            DropdownButtonFormField<AlarmScheduleType>(
              initialValue: _scheduleType,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: const [
                DropdownMenuItem(
                    value: AlarmScheduleType.once, child: Text('Once')),
                DropdownMenuItem(
                    value: AlarmScheduleType.daily, child: Text('Every day')),
                DropdownMenuItem(
                    value: AlarmScheduleType.weekly,
                    child: Text('Selected days')),
                DropdownMenuItem(
                    value: AlarmScheduleType.intervalDays,
                    child: Text('Every N days')),
              ],
              onChanged: (value) => setState(() {
                _scheduleType = value!;
                _error = null;
              }),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(
                  _time.format(context),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            if (_scheduleType == AlarmScheduleType.once)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                trailing: TextButton(
                  onPressed: () => _pickDate(
                    _date,
                    (picked) => _date = picked,
                  ),
                  child: Text(localizations.formatMediumDate(_date)),
                ),
              ),
            if (_scheduleType == AlarmScheduleType.weekly)
              Wrap(
                spacing: 4,
                children: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    FilterChip(
                      label: Text(weekdayShortLabels[day - 1]),
                      selected: _weekdays.contains(day),
                      onSelected: (selected) => setState(() {
                        selected ? _weekdays.add(day) : _weekdays.remove(day);
                        _error = null;
                      }),
                    ),
                ],
              ),
            if (_scheduleType == AlarmScheduleType.intervalDays) ...[
              TextField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Interval in days'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Starting'),
                trailing: TextButton(
                  onPressed: () => _pickDate(
                    _startDate,
                    (picked) => _startDate = picked,
                  ),
                  child: Text(localizations.formatMediumDate(_startDate)),
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            if (_scheduleType == AlarmScheduleType.once)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Delete after dismissal'),
                value: _deleteAfterUse,
                onChanged: (value) => setState(() => _deleteAfterUse = value),
              ),
            DropdownButtonFormField<int>(
              initialValue: _reincarnationCount,
              decoration: const InputDecoration(
                labelText: 'Reminders',
                helperText: 'Extra alarms after the first one, so '
                    'stopping it by accident does not let you oversleep',
                helperMaxLines: 2,
              ),
              items: [
                for (var count = 0; count <= maxReincarnationCount; count++)
                  DropdownMenuItem(
                    value: count,
                    child: Text(count == 0
                        ? 'Off'
                        : count == 1
                            ? '1 extra alarm'
                            : '$count extra alarms'),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _reincarnationCount = value!),
            ),
            if (_reincarnationCount > 0)
              DropdownButtonFormField<int>(
                initialValue: _reincarnationIntervalMinutes,
                decoration: const InputDecoration(labelText: 'Spaced by'),
                items: [
                  for (final minutes in _intervalOptions)
                    DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes min'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _reincarnationIntervalMinutes = value!),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Mission to dismiss'),
              subtitle: Text(_mission.describe()),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                MissionPicker(
                  value: _mission,
                  onChanged: (mission) => setState(() {
                    _mission = mission;
                    _missionTouched = true;
                  }),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Sound, wake style and snooze'),
              children: [
                SoundPicker(
                  label: 'Sound',
                  noneLabel:
                      'Default (${Ringtone.resolve(defaultSound).label})',
                  value: _ringtone == Ringtone.followDefault ? null : _ringtone,
                  onChanged: (value) => setState(() {
                    _ringtone = value ?? Ringtone.followDefault;
                    _ringtoneTouched = true;
                  }),
                ),
                const SizedBox(height: 12),
                SegmentedButton<WakeStyle>(
                  segments: const [
                    ButtonSegment(
                      value: WakeStyle.normal,
                      icon: Icon(Icons.volume_up),
                      label: Text('Normal'),
                    ),
                    ButtonSegment(
                      value: WakeStyle.gentle,
                      icon: Icon(Icons.trending_up),
                      label: Text('Gentle'),
                    ),
                  ],
                  selected: {_wakeStyle},
                  onSelectionChanged: (selection) => setState(() {
                    _wakeStyle = selection.single;
                    _wakeStyleTouched = true;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _wakeStyle == WakeStyle.gentle
                        ? 'The volume rises over '
                            '${gentleFadeDuration.inSeconds} seconds'
                        : 'Rings at full volume right away',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibrate'),
                  value: _vibration != VibrationSetting.off,
                  onChanged: (value) => setState(() {
                    _vibration = value
                        ? VibrationSetting.standard
                        : VibrationSetting.off;
                    _vibrationTouched = true;
                  }),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _snoozeMinutes,
                  decoration: const InputDecoration(labelText: 'Snooze for'),
                  items: [
                    for (final minutes in _snoozeOptions)
                      DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes min'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _snoozeMinutes = value!),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save alarm'),
            ),
          ],
        ),
      ),
    );
  }

  /// A new alarm takes its category's defaults (or the Settings defaults
  /// when the category has none) for every field not picked by hand.
  /// Existing and duplicated alarms keep their own values.
  void _applyCategoryDefaults([CategoryModel? category]) {
    if (widget.alarm != null) return;
    category ??= (ref.read(categoriesProvider).value ?? const [])
        .where((candidate) => candidate.id == _categoryId)
        .firstOrNull;
    final settings =
        ref.read(settingsProvider).value ?? const AppSettings.defaults();
    if (!_ringtoneTouched) {
      _ringtone = category?.defaultRingtone ?? Ringtone.followDefault;
    }
    if (!_vibrationTouched) {
      _vibration = category?.defaultVibration ?? settings.defaultVibration;
    }
    if (!_wakeStyleTouched) {
      _wakeStyle = category?.defaultWakeStyle ?? settings.defaultWakeStyle;
    }
    if (!_missionTouched) {
      _mission = category?.defaultMission ?? const Mission.none();
    }
  }

  Future<void> _createCategory() async {
    final created = await showCategoryEditor(context, ref);
    if (!mounted) return;
    setState(() {
      if (created != null) {
        _categoryId = created.id;
        _applyCategoryDefaults(created);
      }
      // Also resets the field if the dialog was cancelled.
      _categoryFieldVersion++;
    });
  }

  Future<void> _pickTime() async {
    final pickerStyle = ref.read(settingsProvider).value?.timePickerStyle ??
        TimePickerStyle.materialClock;
    final picked = pickerStyle == TimePickerStyle.materialClock
        ? await showTimePicker(context: context, initialTime: _time)
        : await _showCupertinoTimePicker();
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _error = null;
      // Picking an earlier time for a one-time alarm set for today most
      // likely means tomorrow.
      if (_scheduleType == AlarmScheduleType.once &&
          _date == _dateOnly(DateTime.now()) &&
          _onceDateTime().isBefore(DateTime.now())) {
        _date = _nextDateFor(_time);
      }
    });
  }

  Future<TimeOfDay?> _showCupertinoTimePicker() async {
    var selected = _time;
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context, selected),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2026, 1, 1, _time.hour, _time.minute),
                onDateTimeChanged: (value) =>
                    selected = TimeOfDay.fromDateTime(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    DateTime current,
    void Function(DateTime picked) apply,
  ) async {
    final today = _dateOnly(DateTime.now());
    final firstDate = current.isBefore(today) ? current : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() {
        apply(_dateOnly(picked));
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final title = _titleController.text.trim().isEmpty
        ? 'Alarm'
        : _titleController.text.trim();
    final recurrence = RecurrenceRule(
      scheduleType: _scheduleType,
      timeOfDay: _time.hour * 60 + _time.minute,
      scheduledDate: _scheduleType == AlarmScheduleType.once ? _date : null,
      daysOfWeek: _scheduleType == AlarmScheduleType.weekly
          ? {..._weekdays}
          : const <int>{},
      intervalDays: _scheduleType == AlarmScheduleType.intervalDays
          ? int.parse(_intervalController.text.trim())
          : null,
      scheduleStartDate:
          _scheduleType == AlarmScheduleType.intervalDays ? _startDate : null,
    );
    final base = _isEditing ? widget.alarm! : null;
    // The category may have been deleted while the editor was open.
    final categories = ref.read(categoriesProvider).value ?? const [];
    final categoryId = categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : null;
    final alarm = AlarmModel(
      id: base?.id ?? 'alarm-${now.microsecondsSinceEpoch}',
      title: title,
      categoryId: categoryId,
      recurrence: recurrence,
      isEnabled: _isEnabled,
      deleteAfterUse:
          _scheduleType == AlarmScheduleType.once && _deleteAfterUse,
      ringtone: _ringtone,
      vibration: _vibration,
      wakeStyle: _wakeStyle,
      mission: _mission,
      snoozeDuration: Duration(minutes: _snoozeMinutes),
      reincarnationCount: _reincarnationCount,
      reincarnationInterval: Duration(minutes: _reincarnationIntervalMinutes),
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ref.read(alarmServiceProvider).save(alarm);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  String? _validate() {
    switch (_scheduleType) {
      case AlarmScheduleType.once:
        if (_isEnabled && !_onceDateTime().isAfter(DateTime.now())) {
          return 'That time has already passed. Pick a later time or date.';
        }
      case AlarmScheduleType.weekly:
        if (_weekdays.isEmpty) return 'Select at least one day.';
      case AlarmScheduleType.intervalDays:
        final interval = int.tryParse(_intervalController.text.trim());
        if (interval == null || interval < 1 || interval > 365) {
          return 'Enter an interval between 1 and 365 days.';
        }
      case AlarmScheduleType.daily:
        break;
    }
    return null;
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(alarmServiceProvider).delete(widget.alarm!);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  DateTime _onceDateTime() =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  static DateTime _nextDateFor(TimeOfDay time) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final todayAt =
        DateTime(today.year, today.month, today.day, time.hour, time.minute);
    return todayAt.isAfter(now)
        ? today
        : DateTime(today.year, today.month, today.day + 1);
  }

  static int _nearest(int value, List<int> options) {
    return options.reduce(
      (best, option) =>
          (option - value).abs() < (best - value).abs() ? option : best,
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(child: Text('Error: $error'));
}

/// Enabled alarms first by next occurrence, then disabled ones by time.
int _compareAlarms(AlarmModel a, AlarmModel b) {
  if (a.isEnabled != b.isEnabled) return a.isEnabled ? -1 : 1;
  final aNext = a.isEnabled ? a.nextOccurrenceAt : null;
  final bNext = b.isEnabled ? b.nextOccurrenceAt : null;
  if (aNext != null && bNext != null) return aNext.compareTo(bNext);
  if (aNext != null) return -1;
  if (bNext != null) return 1;
  return a.recurrence.timeOfDay.compareTo(b.recurrence.timeOfDay);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// The ⋮ menu in the Alarms title bar.
class AlarmsMenuButton extends ConsumerWidget {
  const AlarmsMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final grouped = settings?.isGroupedView ?? false;
    return PopupMenuButton<String>(
      tooltip: 'More options',
      enabled: settings != null,
      onSelected: (value) {
        if (value == 'group' && settings != null) {
          ref
              .read(settingsRepositoryProvider)
              .save(settings.copyWith(isGroupedView: !grouped));
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'group',
          checked: grouped,
          child: const Text('Group by category'),
        ),
      ],
    );
  }
}
