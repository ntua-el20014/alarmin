import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/data/repositories/settings_repository.dart';
import 'package:alarmin/features/alarms/alarms_screen.dart';
import 'package:alarmin/features/stopwatch/stopwatch_screen.dart';
import 'package:alarmin/features/timer/timer_controller.dart';
import 'package:alarmin/features/timer/timer_screen.dart';

void main() {
  testWidgets('stopwatch offers Finish only while paused', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stopwatchHistoryProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: Scaffold(body: StopwatchScreen())),
      ),
    );

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Flag'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
    expect(find.text('Discard'), findsNothing);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('the timer sun button toggles keep-screen-on with a message',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: TimerScreen())),
      ),
    );

    await tester.tap(find.byIcon(Icons.wb_sunny_outlined));
    await tester.pump();
    expect(container.read(keepScreenOnProvider), isTrue);
    expect(find.text('Screen will stay on'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);

    await tester.tap(find.byIcon(Icons.wb_sunny));
    await tester.pump();
    expect(container.read(keepScreenOnProvider), isFalse);
    expect(find.text('Screen can turn off again'), findsOneWidget);
  });

  testWidgets('the alarms menu toggles grouping by category', (tester) async {
    final saved = <AppSettings>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
          settingsRepositoryProvider
              .overrideWithValue(_RecordingSettings(saved)),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [AlarmsMenuButton()]),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group by category'));
    await tester.pumpAndSettle();

    expect(saved.single.isGroupedView, isTrue);
  });
}

class _RecordingSettings implements SettingsRepository {
  _RecordingSettings(this.saved);

  final List<AppSettings> saved;

  @override
  Future<void> save(AppSettings settings) async => saved.add(settings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
