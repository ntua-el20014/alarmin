import UIKit
import Flutter
import UserNotifications
import alarm

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Required by the alarm plugin: show alarm notifications while the app is
    // in the foreground and keep alarms alive with background fetch.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    SwiftAlarmPlugin.registerBackgroundTasks()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
