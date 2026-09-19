import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category_model.dart';
import '../../data/models/recurrence_rule.dart';

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
            isGroupedView: appSettings.isGroupedView,
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

class _AlarmList extends ConsumerWidget {
  const _AlarmList({
    required this.alarms,
    required this.categories,
    required this.isGroupedView,
  });

  final List<AlarmModel> alarms;
  final List<CategoryModel> categories;
  final bool isGroupedView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final sorted = [...alarms]..sort((a, b) => _compareOccurrences(a, b));

    return Stack(
      children: [
        if (sorted.isEmpty)
          const Center(child: Text('No alarms yet'))
        else if (isGroupedView)
          _GroupedAlarmList(alarms: sorted, categoryById: categoryById)
        else
          _FlatAlarmList(alarms: sorted, categoryById: categoryById),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openEditor(context, ref),
            tooltip: 'Add alarm',
            child: const Icon(Icons.add_alarm),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, [AlarmModel? alarm]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AlarmEditor(alarm: alarm),
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
  const _GroupedAlarmList({required this.alarms, required this.categoryById});

  final List<AlarmModel> alarms;
  final Map<String, CategoryModel> categoryById;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AlarmModel>>{};
    for (final alarm in alarms) {
      grouped.putIfAbsent(alarm.categoryId ?? '', () => []).add(alarm);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              entry.key.isEmpty
                  ? 'Uncategorized'
                  : '${categoryById[entry.key]?.emoji ?? ''} ${categoryById[entry.key]?.name ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final alarm in entry.value)
            _AlarmTile(
              alarm: alarm,
              category: categoryById[alarm.categoryId],
            ),
        ],
      ],
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({required this.alarm, required this.category});

  final AlarmModel alarm;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = alarm.nextOccurrenceAt == null
        ? 'Not scheduled'
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(alarm.nextOccurrenceAt!),
          );
    return ListTile(
      leading:
          Text(category?.emoji ?? '⏰', style: const TextStyle(fontSize: 24)),
      title: Text(alarm.title),
      subtitle: Text(time),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: (enabled) =>
            ref.read(alarmServiceProvider).setEnabled(alarm, enabled),
      ),
    );
  }
}

class _AlarmEditor extends ConsumerStatefulWidget {
  const _AlarmEditor({this.alarm});

  final AlarmModel? alarm;

  @override
  ConsumerState<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends ConsumerState<_AlarmEditor> {
  late final TextEditingController _titleController;
  late AlarmScheduleType _scheduleType;
  late TimeOfDay _time;
  late DateTime _date;
  late int _intervalDays;
  late Set<int> _weekdays;
  String? _categoryId;
  bool _isEnabled = true;
  bool _deleteAfterUse = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    final now = DateTime.now();
    _titleController = TextEditingController(text: alarm?.title ?? '');
    _scheduleType = alarm?.recurrence.scheduleType ?? AlarmScheduleType.daily;
    _time = alarm == null
        ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1)))
        : TimeOfDay.fromDateTime(
            DateTime(2026, 1, 1, alarm.recurrence.timeOfDay ~/ 60,
                alarm.recurrence.timeOfDay % 60),
          );
    _date = alarm?.recurrence.scheduledDate ?? now;
    _intervalDays = alarm?.recurrence.intervalDays ?? 2;
    _weekdays = {...?alarm?.recurrence.daysOfWeek};
    _categoryId = alarm?.categoryId;
    _isEnabled = alarm?.isEnabled ?? true;
    _deleteAfterUse = alarm?.deleteAfterUse ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).when(
          data: (items) => items,
          loading: () => const <CategoryModel>[],
          error: (error, stackTrace) => const <CategoryModel>[],
        );
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.alarm == null ? 'Add alarm' : 'Edit alarm',
                style: Theme.of(context).textTheme.headlineSmall),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
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
              ],
              onChanged: (value) => setState(() => _categoryId = value),
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
              onChanged: (value) => setState(() => _scheduleType = value!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(_time.format(context)),
              ),
            ),
            if (_scheduleType == AlarmScheduleType.once)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(MaterialLocalizations.of(context)
                      .formatMediumDate(_date)),
                ),
              ),
            if (_scheduleType == AlarmScheduleType.weekly)
              Wrap(
                spacing: 4,
                children: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    FilterChip(
                      label: Text(_weekdayLabel(day)),
                      selected: _weekdays.contains(day),
                      onSelected: (selected) => setState(() {
                        selected ? _weekdays.add(day) : _weekdays.remove(day);
                      }),
                    ),
                ],
              ),
            if (_scheduleType == AlarmScheduleType.intervalDays)
              TextFormField(
                initialValue: '$_intervalDays',
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Interval in days'),
                onChanged: (value) => _intervalDays = int.tryParse(value) ?? 2,
              ),
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
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save alarm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final pickerStyle = ref.read(settingsProvider).when(
          data: (settings) => settings.timePickerStyle,
          loading: () => TimePickerStyle.materialClock,
          error: (error, stackTrace) => TimePickerStyle.materialClock,
        );
    final picked = pickerStyle == TimePickerStyle.materialClock
        ? await showTimePicker(context: context, initialTime: _time)
        : await _showCupertinoTimePicker();
    if (picked != null && mounted) setState(() => _time = picked);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_scheduleType == AlarmScheduleType.weekly && _weekdays.isEmpty) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final recurrence = RecurrenceRule(
      scheduleType: _scheduleType,
      timeOfDay: _time.hour * 60 + _time.minute,
      scheduledDate: _scheduleType == AlarmScheduleType.once ? _date : null,
      daysOfWeek: _weekdays,
      intervalDays: _scheduleType == AlarmScheduleType.intervalDays
          ? _intervalDays
          : null,
      scheduleStartDate:
          _scheduleType == AlarmScheduleType.intervalDays ? now : null,
    );
    final alarm = (widget.alarm ??
            AlarmModel(
              id: 'alarm-${now.microsecondsSinceEpoch}',
              title: _titleController.text.trim(),
              recurrence: recurrence,
              isEnabled: _isEnabled,
              deleteAfterUse: _deleteAfterUse,
              ringtone: 'assets/audio/default.mp3',
              vibration: VibrationSetting.standard,
              snoozeDuration: const Duration(minutes: 10),
              reincarnationCount: 2,
              reincarnationInterval: const Duration(minutes: 5),
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      title: _titleController.text.trim(),
      categoryId: _categoryId,
      recurrence: recurrence,
      isEnabled: _isEnabled,
      deleteAfterUse: _deleteAfterUse,
      updatedAt: now,
    );
    await ref.read(alarmServiceProvider).save(alarm);
    if (mounted) Navigator.pop(context);
  }

  String _weekdayLabel(int weekday) => const <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ][weekday - 1];
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(child: Text('Error: $error'));
}

int _compareOccurrences(AlarmModel a, AlarmModel b) {
  if (a.nextOccurrenceAt == null) return 1;
  if (b.nextOccurrenceAt == null) return -1;
  return a.nextOccurrenceAt!.compareTo(b.nextOccurrenceAt!);
}
