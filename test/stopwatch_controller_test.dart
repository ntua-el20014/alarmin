import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/app/providers.dart';
import 'package:alarmin/data/database/app_database.dart' as db;
import 'package:alarmin/data/repositories/stopwatch_repository.dart';
import 'package:alarmin/data/models/stopwatch_models.dart' as domain;
import 'package:alarmin/features/stopwatch/stopwatch_controller.dart';

void main() {
  late db.AppDatabase database;
  late StopwatchRepository repository;
  late ProviderContainer container;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = StopwatchRepository(database);
    container = ProviderContainer(
      overrides: [stopwatchRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('allows flagging while paused', () {
    final controller = container.read(stopwatchControllerProvider.notifier);

    controller.start();
    controller.pause();
    controller.flag();

    final state = container.read(stopwatchControllerProvider);
    expect(state.status, domain.StopwatchSessionStatus.paused);
    expect(state.laps, hasLength(1));
    expect(state.laps.single.sequence, 1);
    expect(state.laps.single.elapsedAtLapMs, state.elapsed.inMilliseconds);
  });

  test('finish saves the completed session and laps', () async {
    final controller = container.read(stopwatchControllerProvider.notifier);

    controller.start();
    controller.flag();
    await controller.finish();

    expect(container.read(stopwatchControllerProvider).hasSession, isFalse);
    final history = await repository.watchHistory().first;
    expect(history, hasLength(1));
    expect(history.single.status, domain.StopwatchSessionStatus.completed);
  });
}
