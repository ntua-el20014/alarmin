import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/main.dart';

void main() {
  testWidgets('navigates between the five app screens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmsProvider.overrideWith((ref) => Stream.value([])),
          categoriesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
          stopwatchHistoryProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Alarms'), findsNWidgets(2));
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Stopwatch'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Timer').last);
    await tester.pump();

    expect(find.text('Timer'), findsNWidgets(2));
    expect(find.text('Alarms'), findsOneWidget);
  });
}
