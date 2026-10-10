import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions and window behavior alarms need to ring visibly.
///
/// Only Android is handled here: on Android 13+ the alarm notification (and
/// its Stop button) is hidden without the notification permission, on
/// Android 12+ exact alarms may be denied, and on Android 14+ the
/// full-screen permission decides whether a ringing alarm wakes the screen.
class AlarmPermissions {
  static const _channel = MethodChannel('alarmin/system');

  static const fullScreenLabel = 'Wake screen for alarms';
  static const batteryLabel = 'Ignore battery optimization';

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  static const _required = <Permission>[
    Permission.notification,
    Permission.scheduleExactAlarm,
  ];

  /// Asks for each missing permission once; does nothing if already granted
  /// or permanently denied (the settings screen links to system settings).
  Future<void> requestMissing() async {
    if (!isSupported) return;
    for (final permission in _required) {
      if (await permission.isDenied) await permission.request();
    }
  }

  Future<Map<String, bool>> status() async {
    if (!isSupported) return const {};
    return {
      'Notifications': await Permission.notification.isGranted,
      'Exact alarms': await Permission.scheduleExactAlarm.isGranted,
      fullScreenLabel: await canWakeScreen(),
      batteryLabel: await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  /// Whether a ringing alarm may turn the screen on over the lock screen.
  Future<bool> canWakeScreen() async {
    if (!isSupported) return true;
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ??
          true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  Future<void> openWakeScreenSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openFullScreenIntentSettings');
  }

  /// Keeps the app visible over the lock screen, with the display on, while
  /// the ring screen is open.
  Future<void> showOverLockScreen(bool show) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setShowOverLockScreen', show);
    } on MissingPluginException {
      // Not running in MainActivity (tests, other embedders).
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!isSupported) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<bool> openSystemSettings() => openAppSettings();
}
