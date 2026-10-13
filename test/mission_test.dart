import 'dart:async';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/models/category_model.dart';
import 'package:alarmin/data/models/mission.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/ringing_alarm.dart';
import 'package:alarmin/data/repositories/alarm_repository.dart';
import 'package:alarmin/data/repositories/category_repository.dart';
import 'package:alarmin/data/repositories/reincarnation_repository.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/data/services/alarm_service.dart';
import 'package:alarmin/features/missions/mission_view.dart';
import 'package:alarmin/features/ringing/ring_screen.dart';

import 'support/fake_alarm_scheduler.dart';

void main() {
  group('MathProblem', () {
    test('answers match the problem at every difficulty', () {
      final random = Random(7);
      for (final difficulty in MathDifficulty.values) {
        for (var i = 0; i < 200; i++) {
          final problem = MathProblem.generate(difficulty, random);
          expect(_evaluate(problem.text), problem.answer, reason: problem.text);
          expect(problem.answer, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('Mission', () {
    test('falls back to the default count and describes itself', () {
      expect(const Mission(type: MissionType.math).count, 3);
      expect(const Mission(type: MissionType.shake).count, 30);
      expect(const Mission.none().count, 0);
      expect(
        const Mission.math(problems: 1).describe(),
        '1 math problem (medium)',
      );
      expect(const Mission.shake(shakes: 20).describe(), 'Shake 20 times');
    });

    test('detects one shake per swing', () async {
      final readings = StreamController<(double, double, double)>();
      final shakes = <void>[];
      final subscription = detectShakes(
        readings.stream,
        debounce: Duration.zero,
      ).listen(shakes.add);

      readings
        ..add((0, 0, 9.8)) // lying still
        ..add((25, 5, 9.8)) // strong swing
        ..add((3, 2, 9.8))
        ..add((0, -30, 0)); // another swing
      await Future<void>.delayed(Duration.zero);

      expect(shakes, hasLength(2));
      await subscription.cancel();
      await readings.close();
    });
  });

  group('saving missions', () {
    late db.AppDatabase database;

    setUp(() => database = db.AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('alarms and categories keep their mission', () async {
      const hardMath =
          Mission.math(difficulty: MathDifficulty.hard, problems: 5);
      final alarms = AlarmRepository(database);
      await alarms.save(_alarm(mission: hardMath));
      expect((await alarms.findById('alarm-1'))?.mission, hardMath);

      final categories = CategoryRepository(database);
      await categories.save(_category(const Mission.shake(shakes: 40)));
      expect(
        (await categories.findById('work'))?.defaultMission,
        const Mission.shake(shakes: 40),
      );
      await categories.save(_category(null));
      expect((await categories.findById('work'))?.defaultMission, isNull);
    });

    test('an alarm with a mission has no Stop button in its notification',
        () async {
      final scheduler = FakeAlarmScheduler();
      addTearDown(scheduler.close);
      final service = AlarmService(
        repository: AlarmRepository(database),
        reincarnationRepository: ReincarnationRepository(database),
        scheduler: scheduler,
        now: () => DateTime(2026, 9, 21, 6),
      );

      await service.save(_alarm(mission: const Mission.shake()));
      expect(
        scheduler.active[primaryNativeId('alarm-1')]?.showStopButton,
        isFalse,
      );

      await service.save(_alarm());
      expect(
        scheduler.active[primaryNativeId('alarm-1')]?.showStopButton,
        isTrue,
      );
    });
  });

  group('RingScreen with a mission', () {
    late StreamController<void> shakes;

    Future<ProviderContainer> pumpTestAlarm(
      WidgetTester tester,
      Mission mission,
    ) async {
      shakes = StreamController<void>.broadcast();
      addTearDown(shakes.close);
      final scheduler = FakeAlarmScheduler();
      addTearDown(scheduler.close);
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          alarmSchedulerProvider.overrideWithValue(scheduler),
          categoriesProvider
              .overrideWith((ref) => Stream.value([_category(mission)])),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
          shakeEventsProvider.overrideWithValue(shakes.stream),
          mathProblemGeneratorProvider.overrideWithValue(
            (_) => const MathProblem('2 + 3', 5),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(ringingAlarmProvider).value =
          RingingAlarm.standalone(testAlarmNativeId);
      container.read(testAlarmCategoryProvider).value = 'work';
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RingScreen()),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('math: stopping needs the right answers', (tester) async {
      final container =
          await pumpTestAlarm(tester, const Mission.math(problems: 2));

      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(find.text('2 + 3 ='), findsOneWidget);
      expect(find.text('Problem 1 of 2'), findsOneWidget);

      await tester.tap(find.text('4'));
      await tester.tap(find.bySemanticsLabel('Check'));
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);
      expect(container.read(ringingAlarmProvider).value, isNotNull);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('5'));
        await tester.tap(find.bySemanticsLabel('Check'));
        await tester.pump();
      }
      await tester.pump();
      expect(container.read(ringingAlarmProvider).value, isNull);
    });

    testWidgets('missions fit a short screen without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(360, 560); // a small phone
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final mission in const [
        Mission.shake(shakes: 10),
        Mission.math(problems: 1),
      ]) {
        await tester.pumpWidget(const SizedBox()); // a fresh ring screen
        await pumpTestAlarm(tester, mission);
        await tester.tap(find.text('Stop'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('shake: stops after enough shakes; Back returns',
        (tester) async {
      final container =
          await pumpTestAlarm(tester, const Mission.shake(shakes: 10));

      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(find.text('Shake your phone'), findsOneWidget);

      await tester.tap(find.text('Back (snooze instead)'));
      await tester.pump();
      expect(find.text('Swipe up to snooze'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        shakes.add(null);
      }
      await tester.pump();
      await tester.pump();
      expect(container.read(ringingAlarmProvider).value, isNull);
    });
  });
}

/// Evaluates "a + b", "a − b", "a × b" and "a × b + c".
int _evaluate(String text) {
  final parts = text.split(' ');
  var result = int.parse(parts[0]);
  if (parts.length >= 3) {
    final b = int.parse(parts[2]);
    result = switch (parts[1]) {
      '+' => result + b,
      '−' => result - b,
      '×' => result * b,
      _ => throw ArgumentError(text),
    };
  }
  if (parts.length == 5) result += int.parse(parts[4]);
  return result;
}

CategoryModel _category(Mission? mission) => CategoryModel(
      id: 'work',
      name: 'Work',
      emoji: '💼',
      defaultMission: mission,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

AlarmModel _alarm({Mission mission = const Mission.none()}) {
  final now = DateTime(2026, 9, 20);
  return AlarmModel(
    id: 'alarm-1',
    title: 'Morning',
    recurrence: const RecurrenceRule(
      scheduleType: AlarmScheduleType.daily,
      timeOfDay: 7 * 60,
    ),
    isEnabled: true,
    deleteAfterUse: false,
    ringtone: 'classic',
    vibration: VibrationSetting.standard,
    mission: mission,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 0,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: now,
    updatedAt: now,
  );
}
