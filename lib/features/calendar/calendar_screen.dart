import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../alarms/alarm_labels.dart';
import '../alarms/alarms_screen.dart';

enum CalendarViewMode { daily, weekly, monthly }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = _dateOnly(DateTime.now());
  DateTime _selectedDay = _dateOnly(DateTime.now());
  CalendarViewMode _viewMode = CalendarViewMode.weekly;

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmsProvider);
    return alarms.when(
      data: (items) => _buildCalendar(context, items),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCalendar(BuildContext context, List<AlarmModel> alarms) {
    // Only expand occurrences for what can be on screen: the focused month
    // plus the partial weeks around it.
    final rangeStart = DateTime(_focusedDay.year, _focusedDay.month, 1 - 7);
    final rangeEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 7);
    final occurrenceMap = ref
        .read(calendarOccurrenceServiceProvider)
        .occurrencesBetween(alarms, rangeStart, rangeEnd);
    final selectedEvents = [
      ...?occurrenceMap[_dateOnly(_selectedDay)],
    ]..sort((a, b) => a.recurrence.timeOfDay.compareTo(b.recurrence.timeOfDay));
    final today = _dateOnly(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(
                value: CalendarViewMode.daily,
                label: Text('Day'),
                icon: Icon(Icons.today),
              ),
              ButtonSegment(
                value: CalendarViewMode.weekly,
                label: Text('Week'),
                icon: Icon(Icons.view_week),
              ),
              ButtonSegment(
                value: CalendarViewMode.monthly,
                label: Text('Month'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) {
              setState(() => _viewMode = selection.first);
            },
          ),
        ),
        if (_viewMode == CalendarViewMode.daily)
          _DayHeader(
            day: _selectedDay,
            onChanged: (day) => setState(() {
              _selectedDay = day;
              _focusedDay = day;
            }),
          )
        else
          TableCalendar<AlarmModel>(
            firstDay: today.subtract(const Duration(days: 3650)),
            lastDay: today.add(const Duration(days: 3650)),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarFormat: _viewMode == CalendarViewMode.monthly
                ? CalendarFormat.month
                : CalendarFormat.week,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            eventLoader: (day) => occurrenceMap[_dateOnly(day)] ?? const [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = _dateOnly(selectedDay);
                _focusedDay = _dateOnly(focusedDay);
              });
            },
            onPageChanged: (focusedDay) =>
                setState(() => _focusedDay = _dateOnly(focusedDay)),
          ),
        const Divider(height: 1),
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(child: Text('No alarms scheduled'))
              : ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) => _CalendarAlarmTile(
                    alarm: selectedEvents[index],
                  ),
                ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.onChanged});

  final DateTime day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              onChanged(DateTime(day.year, day.month, day.day - 1)),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => onChanged(_dateOnly(DateTime.now())),
            child: Text(
              DateFormat.yMMMMEEEEd().format(day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          icon: const Icon(Icons.chevron_right),
          onPressed: () =>
              onChanged(DateTime(day.year, day.month, day.day + 1)),
        ),
      ],
    );
  }
}

class _CalendarAlarmTile extends StatelessWidget {
  const _CalendarAlarmTile({required this.alarm});

  final AlarmModel alarm;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(formatTimeOfDayMinutes(context, alarm.recurrence.timeOfDay)),
      subtitle:
          Text('${alarm.title} · ${describeRecurrence(alarm.recurrence)}'),
      onTap: () => showAlarmEditor(context, alarm: alarm),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
