import 'package:flutter/material.dart';

import '../../data/models/mission.dart';

/// Chooses an alarm's mission: none, math (difficulty and number of
/// problems) or shake (number of shakes). Used by the alarm editor and the
/// category dialog.
class MissionPicker extends StatelessWidget {
  const MissionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Mission value;
  final ValueChanged<Mission> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<MissionType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: MissionType.none, label: Text('None')),
            ButtonSegment(
              value: MissionType.math,
              icon: Icon(Icons.calculate_outlined),
              label: Text('Math'),
            ),
            ButtonSegment(
              value: MissionType.shake,
              icon: Icon(Icons.vibration),
              label: Text('Shake'),
            ),
          ],
          selected: {value.type},
          onSelectionChanged: (selection) =>
              onChanged(value.withType(selection.single)),
        ),
        const SizedBox(height: 4),
        Text(
          switch (value.type) {
            MissionType.none => 'Dismiss with a single tap',
            MissionType.math => 'Solve problems to dismiss, '
                'e.g. ${MathProblem.example(value.difficulty)}',
            MissionType.shake => 'Shake the phone to dismiss',
          },
          style: textTheme.bodySmall,
        ),
        if (value.type == MissionType.math) ...[
          const SizedBox(height: 8),
          SegmentedButton<MathDifficulty>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: MathDifficulty.easy, label: Text('Easy')),
              ButtonSegment(
                value: MathDifficulty.medium,
                label: Text('Medium'),
              ),
              ButtonSegment(value: MathDifficulty.hard, label: Text('Hard')),
            ],
            selected: {value.difficulty},
            onSelectionChanged: (selection) => onChanged(
              Mission.math(difficulty: selection.single, problems: value.count),
            ),
          ),
          DropdownButtonFormField<int>(
            key: ValueKey('math-${value.count}'),
            initialValue: value.count,
            decoration: const InputDecoration(labelText: 'Problems'),
            items: [
              for (final count in Mission.mathProblemOptions)
                DropdownMenuItem(value: count, child: Text('$count')),
            ],
            onChanged: (count) => onChanged(
              Mission.math(difficulty: value.difficulty, problems: count!),
            ),
          ),
        ],
        if (value.type == MissionType.shake)
          DropdownButtonFormField<int>(
            key: ValueKey('shake-${value.count}'),
            initialValue: value.count,
            decoration: const InputDecoration(labelText: 'Shakes'),
            items: [
              for (final count in Mission.shakeOptions)
                DropdownMenuItem(value: count, child: Text('$count times')),
            ],
            onChanged: (count) => onChanged(Mission.shake(shakes: count!)),
          ),
      ],
    );
  }
}
