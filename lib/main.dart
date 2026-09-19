import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'features/alarms/alarms_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stopwatch/stopwatch_screen.dart';
import 'features/timer/timer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final alarmService = container.read(alarmServiceProvider);
  await alarmService.initialize();
  await alarmService.recover();
  container.read(alarmRingHandlerProvider).start();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarmin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recoverAlarms();
    }
  }

  Future<void> _recoverAlarms() async {
    if (!mounted) return;
    await context
        .findAncestorWidgetOfExactType<UncontrolledProviderScope>()
        ?.container
        .read(alarmServiceProvider)
        .recover();
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(selectedScreen.title),
      ),
      body: _selectedIndex == 0
          ? const AlarmsScreen()
          : _selectedIndex == 1
              ? const CalendarScreen()
              : _selectedIndex == 2
                  ? const TimerScreen()
                  : _selectedIndex == 3
                      ? const StopwatchScreen()
                      : _selectedIndex == 4
                          ? const SettingsScreen()
                          : Center(child: Text(selectedScreen.title)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
