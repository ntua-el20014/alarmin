import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions alarms need to ring and be visible.
///
/// Only Android is handled here: on Android 13+ the alarm notification (and
/// its Stop button) is hidden without the notification permission, and on
/// Android 12+ exact alarms may be denied.
class AlarmPermissions {
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
      'Ignore battery optimization':
          await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!isSupported) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<bool> openSystemSettings() => openAppSettings();
}
