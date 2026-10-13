import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/models/app_settings.dart';
import 'package:alarmin/features/settings/settings_screen.dart';

void main() {
  Future<void> pumpSettings(WidgetTester tester, {List<String>? issues}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings.defaults()),
          ),
          categoriesProvider.overrideWith((ref) => Stream.value([])),
          fullScreenAlarmIssuesProvider
              .overrideWith((ref) async => issues ?? const []),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
  }

  testWidgets('lists the categories and opens one', (tester) async {
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    for (final title in [
      'Appearance',
      'Alarms',
      'Sounds',
      'Categories',
      'Permissions and test',
      'About',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Dark theme'), findsNothing);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.text('Time picker'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alarms'));
    await tester.pumpAndSettle();
    expect(find.text('Notify 1 hour before alarms'), findsOneWidget);
  });

  testWidgets('warns on the menu when permissions are missing',
      (tester) async {
    await pumpSettings(tester, issues: ['Notifications', 'Exact alarms']);
    await tester.pumpAndSettle();

    expect(find.text('2 settings need attention'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
