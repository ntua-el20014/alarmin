import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'data/models/app_settings.dart';
import 'data/models/ringing_alarm.dart';
import 'features/alarms/alarms_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/ringing/ring_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stopwatch/stopwatch_screen.dart';
import 'features/timer/timer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final alarmService = container.read(alarmServiceProvider);
  try {
    await alarmService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Alarm plugin failed to initialize: $error\n$stackTrace');
  }
  // Listen before recovering: when the app is launched by a ringing alarm,
  // the plugin replays that ring as soon as someone subscribes.
  container.read(alarmRingHandlerProvider).start();
  unawaited(
    alarmService.recover().catchError((Object error, StackTrace stackTrace) {
      debugPrint('Alarm recovery failed: $error\n$stackTrace');
    }),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ?? AppThemeMode.dark;
    return MaterialApp(
      title: 'Alarmin',
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.modeFor(themeMode),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _pageController = PageController();
  late final ValueNotifier<RingingAlarm?> _ringing;
  bool _ringScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ringing = ref.read(ringingAlarmProvider);
    _ringing.addListener(_showRingScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRingScreen();
      unawaited(_checkPermissions().catchError(
        (Object error) => debugPrint('Permission check failed: $error'),
      ));
    });
  }

  @override
  void dispose() {
    _ringing.removeListener(_showRingScreen);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Back from a system settings page: re-check the permissions.
      ref.invalidate(fullScreenAlarmIssuesProvider);
      unawaited(ref.read(alarmServiceProvider).recover().catchError(
            (Object error) => debugPrint('Alarm recovery failed: $error'),
          ));
    }
  }

  Future<void> _showRingScreen() async {
    final navigator = _navigatorKey.currentState;
    if (_ringScreenOpen || _ringing.value == null || navigator == null) return;
    _ringScreenOpen = true;
    final permissions = ref.read(alarmPermissionsProvider);
    unawaited(permissions.showOverLockScreen(true));
    await navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const RingScreen(),
      ),
    );
    _ringScreenOpen = false;
    unawaited(permissions.showOverLockScreen(false));
    // Another alarm may have started while the previous one was closing.
    if (mounted && _ringing.value != null) unawaited(_showRingScreen());
  }

  Future<void> _checkPermissions() async {
    await ref.read(alarmPermissionsProvider).requestMissing();
    // Whatever is still missing for full-screen alarms is shown as a banner
    // on the Alarms tab (never as a dialog over a ringing alarm).
    ref.invalidate(fullScreenAlarmIssuesProvider);
  }

  static const _screens = <_AppScreen>[
    _AppScreen('Alarms', Icons.alarm),
    _AppScreen('Calendar', Icons.calendar_month),
    _AppScreen('Timer', Icons.timer),
    _AppScreen('Stopwatch', Icons.av_timer),
    _AppScreen('Settings', Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedScreen = _screens[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedScreen.title),
        actions: [if (_selectedIndex == 0) const AlarmsMenuButton()],
      ),
      // Swipe left/right between the tabs. Horizontal drags inside a page
      // (for example the calendar's week strip) still go to that page.
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          AlarmsScreen(),
          CalendarScreen(),
          TimerScreen(),
          StopwatchScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Jump rather than animate, so tapping a far tab does not flash
          // through the pages in between.
          _pageController.jumpToPage(index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          for (final screen in _screens)
            BottomNavigationBarItem(
              icon: Icon(screen.icon),
              label: screen.title,
            ),
        ],
      ),
    );
  }
}

class _AppScreen {
  const _AppScreen(this.title, this.icon);

  final String title;
  final IconData icon;
}
