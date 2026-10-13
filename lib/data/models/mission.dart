import 'dart:math';

/// Stored by index: keep the order.
enum MissionType { none, math, shake }

/// Stored by index: keep the order.
enum MathDifficulty { easy, medium, hard }

/// A task that must be completed to dismiss an alarm, proving the user is
/// awake. Snoozing never needs one.
class Mission {
  const Mission({
    this.type = MissionType.none,
    this.difficulty = MathDifficulty.medium,
    int count = 0,
  }) : _count = count;

  const Mission.none() : this();

  const Mission.math({
    MathDifficulty difficulty = MathDifficulty.medium,
    int problems = defaultMathProblems,
  }) : this(type: MissionType.math, difficulty: difficulty, count: problems);

  const Mission.shake({int shakes = defaultShakes})
      : this(type: MissionType.shake, count: shakes);

  static const mathProblemOptions = [1, 2, 3, 4, 5];
  static const defaultMathProblems = 3;
  static const shakeOptions = [10, 20, 30, 40, 50];
  static const defaultShakes = 30;

  final MissionType type;

  /// Only used by [MissionType.math].
  final MathDifficulty difficulty;
  final int _count;

  bool get isNone => type == MissionType.none;

  /// Problems to solve or shakes to make.
  int get count => switch (type) {
        MissionType.none => 0,
        MissionType.math => _count > 0 ? _count : defaultMathProblems,
        MissionType.shake => _count > 0 ? _count : defaultShakes,
      };

  /// A fresh mission of [type], keeping the other settings when they apply.
  Mission withType(MissionType type) => switch (type) {
        MissionType.none => const Mission.none(),
        MissionType.math => Mission.math(difficulty: difficulty),
        MissionType.shake => const Mission.shake(),
      };

  String describe() => switch (type) {
        MissionType.none => 'None',
        MissionType.math =>
          '$count ${count == 1 ? 'math problem' : 'math problems'} '
              '(${difficulty.name})',
        MissionType.shake => 'Shake $count times',
      };

  @override
  bool operator ==(Object other) =>
      other is Mission &&
      other.type == type &&
      other.count == count &&
      (type != MissionType.math || other.difficulty == difficulty);

  @override
  int get hashCode =>
      Object.hash(type, count, type == MissionType.math ? difficulty : null);
}

/// One arithmetic problem of a math mission.
class MathProblem {
  const MathProblem(this.text, this.answer);

  final String text;
  final int answer;

  /// Easy: one addition or subtraction up to 20. Medium: two-digit addition
  /// or a times-table product. Hard: a two-digit product plus a number.
  factory MathProblem.generate(MathDifficulty difficulty, Random random) {
    int between(int min, int max) => min + random.nextInt(max - min + 1);
    switch (difficulty) {
      case MathDifficulty.easy:
        final a = between(2, 20);
        final b = between(1, 20);
        if (random.nextBool() && a > b) return MathProblem('$a − $b', a - b);
        return MathProblem('$a + $b', a + b);
      case MathDifficulty.medium:
        if (random.nextBool()) {
          final a = between(12, 89);
          final b = between(11, 89);
          return MathProblem('$a + $b', a + b);
        }
        final a = between(3, 9);
        final b = between(6, 12);
        return MathProblem('$a × $b', a * b);
      case MathDifficulty.hard:
        final a = between(11, 19);
        final b = between(3, 9);
        final c = between(10, 99);
        return MathProblem('$a × $b + $c', a * b + c);
    }
  }

  /// Shown in the editor so the difficulty levels mean something.
  static String example(MathDifficulty difficulty) => switch (difficulty) {
        MathDifficulty.easy => '14 + 7',
        MathDifficulty.medium => '47 + 38  or  7 × 8',
        MathDifficulty.hard => '13 × 7 + 45',
      };
}
