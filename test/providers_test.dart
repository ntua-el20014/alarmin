import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/models/app_settings.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('exposes seeded settings and categories through providers', () async {
    final settings = await _firstValue(container, settingsProvider);
    final categories = await _firstValue(container, categoriesProvider);

    expect(settings.timePickerStyle, TimePickerStyle.materialClock);
    expect(settings.isGroupedView, isFalse);
    expect(categories, hasLength(3));
  });

  test('exposes empty alarm and stopwatch streams initially', () async {
    expect(await _firstValue(container, alarmsProvider), isEmpty);
    expect(await _firstValue(container, stopwatchHistoryProvider), isEmpty);
  });
}

Future<T> _firstValue<T>(
  ProviderContainer container,
  StreamProvider<T> provider,
) {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = container.listen(
    provider,
    (previous, next) {
      if (!completer.isCompleted && next.hasValue) {
        completer.complete(next.value);
        subscription.close();
      }
    },
    fireImmediately: true,
  );
  return completer.future.timeout(const Duration(seconds: 5));
}
