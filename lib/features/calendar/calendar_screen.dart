import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';

enum CalendarViewMode { daily, weekly }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
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
    final occurrenceMap =
        ref.read(calendarOccurrenceServiceProvider).occurrencesBetween(
              alarms,
              _focusedDay.subtract(const Duration(days: 370)),
              _focusedDay.add(const Duration(days: 370)),
            );
    final selectedEvents = occurrenceMap[_dateOnly(_selectedDay)] ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(
                value: CalendarViewMode.daily,
                label: Text('Daily'),
                icon: Icon(Icons.today),
              ),
              ButtonSegment(
                value: CalendarViewMode.weekly,
                label: Text('Weekly'),
                icon: Icon(Icons.view_week),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) {
              setState(() => _viewMode = selection.first);
            },
          ),
        ),
        TableCalendar<AlarmModel>(
          firstDay: DateTime.now().subtract(const Duration(days: 3650)),
          lastDay: DateTime.now().add(const Duration(days: 3650)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          calendarFormat: _viewMode == CalendarViewMode.daily
              ? CalendarFormat.week
              : CalendarFormat.week,
          availableCalendarFormats: const {CalendarFormat.week: 'Week'},
          eventLoader: (day) => occurrenceMap[_dateOnly(day)] ?? const [],
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) =>
              setState(() => _focusedDay = focusedDay),
        ),
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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _CalendarAlarmTile extends StatelessWidget {
  const _CalendarAlarmTile({required this.alarm});

  final AlarmModel alarm;

  @override
  Widget build(BuildContext context) {
    final time = alarm.nextOccurrenceAt == null
        ? 'Scheduled'
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(alarm.nextOccurrenceAt!),
          );
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(alarm.title),
      subtitle: Text(time),
    );
  }
}
