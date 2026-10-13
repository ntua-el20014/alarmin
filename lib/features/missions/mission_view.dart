import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../data/models/mission.dart';

/// One event per detected shake of the phone. Overridden in tests.
final shakeEventsProvider = Provider<Stream<void>>((ref) {
  return detectShakes(
    accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .map((event) => (event.x, event.y, event.z)),
  );
});

/// Creates the problems of a math mission. Overridden in tests.
final mathProblemGeneratorProvider =
    Provider<MathProblem Function(MathDifficulty)>((ref) {
  final random = Random();
  return (difficulty) => MathProblem.generate(difficulty, random);
});

/// Turns raw accelerometer readings (m/s², gravity included) into shakes: a
/// reading above [threshold] g counts once, then readings are ignored for
/// [debounce] so one swing is not counted several times.
Stream<void> detectShakes(
  Stream<(double, double, double)> readings, {
  double threshold = 2.2,
  Duration debounce = const Duration(milliseconds: 280),
}) {
  DateTime? last;
  return readings.where((reading) {
    final (x, y, z) = reading;
    final force = sqrt(x * x + y * y + z * z) / 9.81;
    if (force < threshold) return false;
    final now = DateTime.now();
    if (last != null && now.difference(last!) < debounce) return false;
    last = now;
    return true;
  });
}

/// Full-screen mission shown instead of the ring controls when the user
/// dismisses an alarm. The alarm keeps ringing until [onCompleted].
class MissionView extends StatelessWidget {
  const MissionView({
    super.key,
    required this.mission,
    required this.onCompleted,
    required this.onBack,
  });

  final Mission mission;
  final VoidCallback onCompleted;

  /// Back to the ring screen, for example to snooze instead.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onBackground = colors.onPrimaryContainer;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryContainer, colors.surfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                Text(
                  'Prove you are awake',
                  style: textTheme.titleLarge?.copyWith(color: onBackground),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete the mission to stop the alarm',
                  style: textTheme.bodyMedium?.copyWith(color: onBackground),
                ),
                Expanded(
                  child: switch (mission.type) {
                    MissionType.math => MathMission(
                        difficulty: mission.difficulty,
                        problems: mission.count,
                        onCompleted: onCompleted,
                      ),
                    MissionType.shake => ShakeMission(
                        shakes: mission.count,
                        onCompleted: onCompleted,
                      ),
                    MissionType.none => const SizedBox.shrink(),
                  },
                ),
                TextButton.icon(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, color: onBackground),
                  label: Text(
                    'Back (snooze instead)',
                    style: TextStyle(color: onBackground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MathMission extends ConsumerStatefulWidget {
  const MathMission({
    super.key,
    required this.difficulty,
    required this.problems,
    required this.onCompleted,
  });

  final MathDifficulty difficulty;
  final int problems;
  final VoidCallback onCompleted;

  @override
  ConsumerState<MathMission> createState() => _MathMissionState();
}

class _MathMissionState extends ConsumerState<MathMission> {
  static const _maxDigits = 5;

  late MathProblem _problem = _next();
  int _solved = 0;
  String _input = '';
  bool _wrong = false;

  MathProblem _next() =>
      ref.read(mathProblemGeneratorProvider)(widget.difficulty);

  void _type(String digit) {
    if (_input.length >= _maxDigits) return;
    setState(() {
      _input += digit;
      _wrong = false;
    });
  }

  void _erase() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _submit() {
    if (_input.isEmpty) return;
    if (int.tryParse(_input) != _problem.answer) {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _input = '';
      });
      return;
    }
    if (_solved + 1 >= widget.problems) {
      widget.onCompleted();
      return;
    }
    setState(() {
      _solved++;
      _input = '';
      _wrong = false;
      _problem = _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onBackground = colors.onPrimaryContainer;

    return Column(
      children: [
        const Spacer(),
        Text(
          'Problem ${_solved + 1} of ${widget.problems}',
          style: textTheme.labelLarge?.copyWith(color: onBackground),
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            '${_problem.text} =',
            style: textTheme.displayMedium?.copyWith(color: onBackground),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _wrong ? colors.error : onBackground,
                width: 2,
              ),
            ),
          ),
          child: Text(
            _input.isEmpty ? (_wrong ? 'Try again' : ' ') : _input,
            textAlign: TextAlign.center,
            style: (_input.isEmpty && _wrong
                    ? textTheme.titleLarge
                    : textTheme.displaySmall)
                ?.copyWith(color: _wrong ? colors.error : onBackground),
          ),
        ),
        const Spacer(),
        _Keypad(onDigit: _type, onErase: _erase, onSubmit: _submit),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onErase,
    required this.onSubmit,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onErase;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback onPressed, {bool filled = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 60,
            child: filled
                ? FilledButton(onPressed: onPressed, child: child)
                : FilledButton.tonal(onPressed: onPressed, child: child),
          ),
        ),
      );
    }

    Widget digit(String value) => key(
          Text(value, style: const TextStyle(fontSize: 24)),
          () => onDigit(value),
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final value in row) digit(value)]),
          Row(
            children: [
              key(const Icon(Icons.backspace_outlined, semanticLabel: 'Erase'),
                  onErase),
              digit('0'),
              key(const Icon(Icons.check, semanticLabel: 'Check'), onSubmit,
                  filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class ShakeMission extends ConsumerStatefulWidget {
  const ShakeMission({
    super.key,
    required this.shakes,
    required this.onCompleted,
  });

  final int shakes;
  final VoidCallback onCompleted;

  @override
  ConsumerState<ShakeMission> createState() => _ShakeMissionState();
}

class _ShakeMissionState extends ConsumerState<ShakeMission> {
  StreamSubscription<void>? _subscription;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(shakeEventsProvider).listen((_) {
      if (!mounted || _count >= widget.shakes) return;
      HapticFeedback.lightImpact();
      setState(() => _count++);
      if (_count >= widget.shakes) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onBackground = colors.onPrimaryContainer;
    final remaining = widget.shakes - _count;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: _count / widget.shakes,
                strokeWidth: 12,
                color: onBackground,
                backgroundColor: onBackground.withValues(alpha: 0.15),
              ),
              Center(
                child: Text(
                  '$remaining',
                  style: textTheme.displayLarge?.copyWith(color: onBackground),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Icon(Icons.vibration, size: 40, color: onBackground),
        const SizedBox(height: 8),
        Text(
          'Shake your phone',
          style: textTheme.headlineSmall?.copyWith(color: onBackground),
        ),
        Text(
          '$_count of ${widget.shakes}',
          style: textTheme.bodyLarge?.copyWith(color: onBackground),
        ),
      ],
    );
  }
}
