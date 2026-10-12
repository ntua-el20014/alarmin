import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime permissions and window behavior alarms need to ring visibly.
///
/// Only Android is handled here: on Android 13+ the alarm notification (and
/// its Stop button) is hidden without the notification permission, on
/// Android 12+ exact alarms may be denied, and on Android 14+ the
/// full-screen permission decides whether a ringing alarm wakes the screen.
class AlarmPermissions {
  static const _channel = MethodChannel('alarmin/system');

  static const fullScreenLabel = 'Wake screen for alarms';
  static const overlayLabel = 'Open alarm over other apps';
  static const batteryLabel = 'Ignore battery optimization';
  static const lockScreenLabel = 'Show on lock screen';

  /// Set once the user opened the maker's permission page on phones where
  /// the lock screen setting cannot be read back.
  static const _lockScreenOpenedKey = 'lockScreenSettingsOpened';

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
      overlayLabel: await Permission.systemAlertWindow.isGranted,
      batteryLabel: await Permission.ignoreBatteryOptimizations.isGranted,
      if (await canShowOnLockScreen() case final allowed?)
        lockScreenLabel: allowed,
    };
  }

  /// The permissions a ringing alarm needs to take over the screen (like the
  /// Clock app) that are still missing, by label. Empty when all is set.
  Future<List<String>> missingForFullScreenAlarm() async {
    if (!isSupported) return const [];
    return [
      if (!await Permission.notification.isGranted) 'Notifications',
      if (!await canWakeScreen()) fullScreenLabel,
      if (!await Permission.systemAlertWindow.isGranted) overlayLabel,
      if (await canShowOnLockScreen() == false) lockScreenLabel,
    ];
  }

  /// Opens the system page (or prompt) that grants the permission [label].
  Future<void> request(String label) async {
    if (!isSupported) return;
    switch (label) {
      case fullScreenLabel:
        await openWakeScreenSettings();
      case overlayLabel:
        await Permission.systemAlertWindow.request();
      case lockScreenLabel:
        await openLockScreenSettings();
      case batteryLabel:
        await Permission.ignoreBatteryOptimizations.request();
      case 'Notifications':
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) await openAppSettings();
      default:
        await openAppSettings();
    }
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

  /// Whether the phone maker's own lock screen setting (Xiaomi, vivo, OPPO,
  /// Huawei...) lets alarms open over the lock screen; null on phones that
  /// have no such setting. Where it cannot be read back, it counts as
  /// allowed once the user has opened its page.
  Future<bool?> canShowOnLockScreen() async {
    if (!isSupported) return null;
    final String? state;
    try {
      state = await _channel.invokeMethod<String>('lockScreenPermission');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    switch (state) {
      case 'granted':
        return true;
      case 'denied':
        return false;
      case 'unknown':
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_lockScreenOpenedKey) ?? false;
      default:
        return null;
    }
  }

  Future<void> openLockScreenSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openLockScreenPermissionSettings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockScreenOpenedKey, true);
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

  /// Keeps the display on while the app is visible (the timer's sun button).
  Future<void> keepScreenOn(bool keepOn) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', keepOn);
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
