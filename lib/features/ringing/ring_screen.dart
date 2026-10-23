import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/category_model.dart';
import '../../data/models/mission.dart';
import '../../data/models/ringing_alarm.dart';
import '../../data/models/ringtone.dart';
import '../../data/services/alarm_scheduler.dart';
import '../missions/mission_view.dart';
import 'emoji_palette.dart';
import 'swipe_up_to_confirm.dart';

/// Full-screen page shown while an alarm or the timer is ringing.
///
/// The alarm's category emoji is shown large and tints the whole screen, so
/// the user can tell what the alarm is about at a glance. The page closes
/// itself when nothing is ringing any more (also when the alarm was stopped
/// from its notification).
class RingScreen extends ConsumerStatefulWidget {
  const RingScreen({super.key});

  @override
  ConsumerState<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends ConsumerState<RingScreen> {
  /// The test alarm snoozes briefly so snoozing can be tried out quickly.
  static const _testSnooze = Duration(minutes: 1);

  /// A button press that has not finished by then is treated as stuck: the
  /// ring is stopped directly and the screen closes, so it can never trap
  /// the user.
  static const _actionTimeout = Duration(seconds: 8);

  late final ValueNotifier<RingingAlarm?> _ringing;
  bool _busy = false;
  bool _closing = false;

  /// While a mission is on screen: the ring it belongs to and what to do
  /// once it is completed.
  (int, Future<void> Function())? _mission;

  @override
  void initState() {
    super.initState();
    _ringing = ref.read(ringingAlarmProvider);
    _ringing.addListener(_closeWhenSilent);
  }

  @override
  void dispose() {
    _ringing.removeListener(_closeWhenSilent);
    super.dispose();
  }

  void _closeWhenSilent() {
    if (_ringing.value == null) _close();
  }

  /// Removes this screen's own route. A plain `pop()` would close whatever
  /// is on top instead (for example a dialog opened over the ring screen),
  /// leaving an empty ring screen that cannot be left.
  void _close() {
    if (_closing || !mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _closing = true;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ringing = _ringing.value;
    try {
      await action().timeout(_actionTimeout);
    } on TimeoutException {
      if (ringing != null) {
        unawaited(ref
            .read(alarmSchedulerProvider)
            .cancel(ringing.nativeId)
            .catchError((Object _) {}));
      }
      if (_ringing.value?.nativeId == ringing?.nativeId) _ringing.value = null;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Runs [action] right away, or after [mission] is completed.
  void _afterMission(
    RingingAlarm ringing,
    Mission mission,
    Future<void> Function() action,
  ) {
    if (mission.isNone) {
      _run(action);
    } else {
      setState(() => _mission = (ringing.nativeId, action));
    }
  }

  Future<void> _snooze(RingingAlarm ringing) {
    final handler = ref.read(alarmRingHandlerProvider);
    final alarm = ringing.alarm;
    if (alarm != null) {
      return handler.snooze(alarm, nativeId: ringing.nativeId);
    }
    final settings = ref.read(settingsProvider).value;
    return handler.snoozeStandalone(
      ringing,
      after: ringing.nativeId == testAlarmNativeId
          ? _testSnooze
          : settings?.defaultSnoozeDuration ?? const Duration(minutes: 10),
      ringtone: (ringing.nativeId == timerNativeId
              ? settings?.effectiveTimerRingtone
              : settings?.defaultRingtone) ??
          Ringtone.fallbackId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final testCategoryId = ref.watch(testAlarmCategoryProvider);

    return PopScope(
      // Back is blocked only while something is actually ringing.
      canPop: _ringing.value == null,
      child: ValueListenableBuilder<RingingAlarm?>(
        valueListenable: _ringing,
        builder: (context, ringing, _) {
          if (ringing == null) {
            // Opened or left over after the ring ended: close right away.
            WidgetsBinding.instance.addPostFrameCallback((_) => _close());
            return const Scaffold();
          }
          return ValueListenableBuilder<String?>(
            valueListenable: testCategoryId,
            builder: (context, testCategory, _) {
              final category = _categoryFor(ringing, categories, testCategory);
              final emoji = category?.emoji ??
                  (ringing.nativeId == timerNativeId ? '⏳' : '⏰');
              // The test alarm tries out its category's mission.
              final mission = ringing.alarm?.mission ??
                  (ringing.nativeId == testAlarmNativeId
                      ? category?.defaultMission
                      : null) ??
                  const Mission.none();
              final pending = _mission;
              return FutureBuilder<Color?>(
                key: ValueKey(emoji),
                future: EmojiPalette.seedColor(emoji),
                builder: (context, snapshot) {
                  final seed = snapshot.data;
                  final theme = Theme.of(context);
                  return Theme(
                    data: seed == null
                        ? theme
                        : theme.copyWith(
                            colorScheme: EmojiPalette.schemeFor(
                              seed,
                              theme.brightness,
                            ),
                          ),
                    child: pending != null && pending.$1 == ringing.nativeId
                        ? MissionView(
                            mission: mission,
                            onCompleted: () {
                              setState(() => _mission = null);
                              _run(pending.$2);
                            },
                            onBack: () => setState(() => _mission = null),
                          )
                        : _RingBody(
                            ringing: ringing,
                            emoji: emoji,
                            category: category,
                            busy: _busy,
                            onSnooze: () => _run(() => _snooze(ringing)),
                            onStop: () => _afterMission(
                              ringing,
                              mission,
                              () => ref
                                  .read(alarmRingHandlerProvider)
                                  .stop(ringing),
                            ),
                            onTurnOffReminders: ringing.alarm == null
                                ? null
                                : () => _afterMission(
                                      ringing,
                                      mission,
                                      () => ref
                                          .read(alarmRingHandlerProvider)
                                          .dismissAll(
                                            ringing.alarm!,
                                            nativeId: ringing.nativeId,
                                          ),
                                    ),
                          ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  CategoryModel? _categoryFor(
    RingingAlarm ringing,
    List<CategoryModel> categories,
    String? testCategoryId,
  ) {
    final categoryId = ringing.alarm?.categoryId ??
        (ringing.nativeId == testAlarmNativeId ? testCategoryId : null);
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }
}

class _RingBody extends StatelessWidget {
  const _RingBody({
    required this.ringing,
    required this.emoji,
    required this.category,
    required this.busy,
    required this.onSnooze,
    required this.onStop,
    this.onTurnOffReminders,
  });

  final RingingAlarm ringing;
  final String emoji;
  final CategoryModel? category;
  final bool busy;
  final VoidCallback onSnooze;
  final VoidCallback onStop;
  final VoidCallback? onTurnOffReminders;

  @override
  Widget build(BuildContext context) {
    final reminders = ringing.upcomingReminders;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onBackground = colors.onPrimaryContainer;
    final showTitle =
        ringing.title.isNotEmpty && ringing.title != category?.name;
    final canTurnOffReminders =
        reminders.isNotEmpty && onTurnOffReminders != null;

    return Scaffold(
      body: Container(
        // Fill the screen: on its own the background is only as wide as
        // its content, leaving a dark band beside a narrow mission.
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryContainer, colors.surfaceContainerLow],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Column(
              children: [
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) => Text(
                    TimeOfDay.fromDateTime(snapshot.data ?? DateTime.now())
                        .format(context),
                    style:
                        textTheme.displayMedium?.copyWith(color: onBackground),
                  ),
                ),
                const Spacer(),
                // Scales down on short screens instead of overflowing.
                Flexible(
                  flex: 6,
                  child: FittedBox(child: _PulsingEmoji(emoji: emoji)),
                ),
                const SizedBox(height: 16),
                if (category != null)
                  Text(
                    category!.name,
                    style: textTheme.titleMedium?.copyWith(color: onBackground),
                  ),
                if (showTitle)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ringing.title,
                      style: textTheme.headlineSmall
                          ?.copyWith(color: onBackground),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                if (reminders.isNotEmpty) ...[
                  Text(
                    '${reminders.length == 1 ? 'Reminder' : 'Reminders'} at '
                    '${reminders.map((at) => TimeOfDay.fromDateTime(at).format(context)).join(', ')}',
                    style: textTheme.bodyLarge?.copyWith(color: onBackground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (ringing.canSnooze) ...[
                  SwipeUpToConfirm(
                    label: 'Swipe up to snooze',
                    color: onBackground,
                    enabled: !busy,
                    onConfirmed: onSnooze,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: busy ? null : onStop,
                    // A tap keeps the reminders, which exist precisely to
                    // survive an accidental dismiss; a deliberate hold turns
                    // them off as well.
                    onLongPress: busy || !canTurnOffReminders
                        ? null
                        : onTurnOffReminders,
                    style: FilledButton.styleFrom(
                      textStyle: textTheme.titleLarge,
                    ),
                    child: Text(ringing.alarm == null ? 'Stop' : 'Dismiss'),
                  ),
                ),
                if (canTurnOffReminders) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Hold Dismiss to turn off reminders too',
                    style: textTheme.labelLarge?.copyWith(color: onBackground),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The category emoji, gently pulsing so the screen reads as "ringing".
class _PulsingEmoji extends StatefulWidget {
  const _PulsingEmoji({required this.emoji});

  final String emoji;

  @override
  State<_PulsingEmoji> createState() => _PulsingEmojiState();
}

class _PulsingEmojiState extends State<_PulsingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.emoji,
        style: const TextStyle(fontSize: 160, height: 1.1),
      ),
    );
  }
}
