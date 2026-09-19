import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/main.dart';

void main() {
  testWidgets('navigates between the five app screens',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Alarms'), findsNWidgets(3));
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Stopwatch'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Timer').last);
    await tester.pump();

    expect(find.text('Timer'), findsNWidgets(3));
    expect(find.text('Alarms'), findsOneWidget);
  });
}
