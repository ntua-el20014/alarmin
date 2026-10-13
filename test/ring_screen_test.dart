import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/models/alarm_model.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/models/category_model.dart';
import 'package:alarmin/data/models/recurrence_rule.dart';
import 'package:alarmin/data/models/ringing_alarm.dart';
import 'package:alarmin/data/services/alarm_scheduler.dart';
import 'package:alarmin/features/ringing/emoji_palette.dart';
import 'package:alarmin/features/ringing/ring_screen.dart';
import 'package:alarmin/features/ringing/swipe_up_to_confirm.dart';

void main() {
  group('EmojiPalette.dominantColor', () {
    Uint8List pixels(List<List<int>> rgbaPixels) =>
        Uint8List.fromList([for (final pixel in rgbaPixels) ...pixel]);

    test('picks the most colorful hue over outlines and highlights', () {
      final color = EmojiPalette.dominantColor(pixels([
        for (var i = 0; i < 40; i++) [220, 30, 40, 255], // red body
        for (var i = 0; i < 30; i++) [20, 20, 20, 255], // black outline
        for (var i = 0; i < 20; i++) [250, 250, 250, 255], // white shine
        for (var i = 0; i < 10; i++) [40, 90, 220, 255], // small blue part
        for (var i = 0; i < 50; i++) [0, 0, 0, 0], // transparent
      ]))!;

      expect(color.r, greaterThan(color.g));
      expect(color.r, greaterThan(color.b));
    });

    test('returns a grey for colorless emoji such as fog', () {
      final color = EmojiPalette.dominantColor(pixels([
        for (var i = 0; i < 50; i++) [180, 180, 185, 255],
        for (var i = 0; i < 50; i++) [140, 140, 145, 255],
      ]))!;

      final hsv = HSVColor.fromColor(color);
      expect(hsv.saturation, lessThan(0.1));
    });

    test('returns null when nothing was drawn', () {
      expect(
        EmojiPalette.dominantColor(pixels([
          for (var i = 0; i < 10; i++) [0, 0, 0, 0],
        ])),
        isNull,
      );
    });
  });

  group('SwipeUpToConfirm', () {
    Future<List<int>> pumpSwipe(WidgetTester tester) async {
      final confirmations = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SwipeUpToConfirm(
                label: 'Swipe up to snooze',
                onConfirmed: () => confirmations.add(1),
              ),
            ),
          ),
        ),
      );
      return confirmations;
    }

    testWidgets('fires after swiping up far enough', (tester) async {
      final confirmations = await pumpSwipe(tester);

      await tester.drag(find.text('Swipe up to snooze'), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmations, hasLength(1));
    });

    testWidgets('a tap or a short swipe does nothing', (tester) async {
      final confirmations = await pumpSwipe(tester);

      await tester.tap(find.text('Swipe up to snooze'));
      await tester.pump();
      await tester.timedDrag(
        find.text('Swipe up to snooze'),
        const Offset(0, -40),
        const Duration(milliseconds: 500),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmations, isEmpty);
    });
  });

  group('RingScreen closing', () {
    Future<(ProviderContainer, GlobalKey<NavigatorState>)> pumpHome(
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('home')),
          ),
        ),
      );
      return (container, navigator);
    }

    testWidgets('closes its own route even when a dialog is on top',
        (tester) async {
      final (container, navigator) = await pumpHome(tester);
      container.read(ringingAlarmProvider).value =
          RingingAlarm.standalone(testAlarmNativeId);
      navigator.currentState!
          .push(MaterialPageRoute<void>(builder: (_) => const RingScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AlertDialog(content: Text('on top')),
      );
      await tester.pump(const Duration(milliseconds: 500));

      container.read(ringingAlarmProvider).value = null;
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RingScreen), findsNothing);
      expect(find.text('on top'), findsOneWidget);
    });

    testWidgets('closes itself if nothing is ringing when it opens',
        (tester) async {
      final (_, navigator) = await pumpHome(tester);

      navigator.currentState!
          .push(MaterialPageRoute<void>(builder: (_) => const RingScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RingScreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('RingScreen', () {
    final category = CategoryModel(
      id: 'health',
      name: 'Health',
      emoji: '💊',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    Future<ProviderContainer> pumpRingScreen(
      WidgetTester tester,
      RingingAlarm ringing,
    ) async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Stream.value([category])),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(ringingAlarmProvider).value = ringing;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RingScreen()),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('shows the category emoji with snooze and dismiss',
        (tester) async {
      await pumpRingScreen(
        tester,
        RingingAlarm(
          nativeId: 1,
          title: 'Vitamins',
          alarm: _alarm(categoryId: category.id),
          canSnooze: true,
        ),
      );

      expect(find.text('💊'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Vitamins'), findsOneWidget);
      expect(find.text('Swipe up to snooze'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('the test alarm previews its category and can snooze',
        (tester) async {
      final container = await pumpRingScreen(
        tester,
        RingingAlarm.standalone(testAlarmNativeId),
      );
      container.read(testAlarmCategoryProvider).value = category.id;
      await tester.pump();

      expect(find.text('💊'), findsOneWidget);
      expect(find.text('Swipe up to snooze'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('an alarm without a category shows a clock', (tester) async {
      await pumpRingScreen(
        tester,
        RingingAlarm(
          nativeId: 1,
          title: 'Wake up',
          alarm: _alarm(),
          canSnooze: true,
        ),
      );

      expect(find.text('⏰'), findsOneWidget);
      expect(find.text('Swipe up to snooze'), findsOneWidget);
    });
  });
}

AlarmModel _alarm({String? categoryId}) {
  final now = DateTime(2026, 9, 21);
  return AlarmModel(
    id: 'alarm-1',
    title: 'Vitamins',
    categoryId: categoryId,
    recurrence: const RecurrenceRule(
      scheduleType: AlarmScheduleType.daily,
      timeOfDay: 8 * 60,
    ),
    isEnabled: true,
    deleteAfterUse: false,
    ringtone: 'classic',
    vibration: VibrationSetting.standard,
    snoozeDuration: const Duration(minutes: 10),
    reincarnationCount: 2,
    reincarnationInterval: const Duration(minutes: 5),
    createdAt: now,
    updatedAt: now,
  );
}
