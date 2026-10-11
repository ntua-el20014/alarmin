package com.example.alarmin

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.lifecycle.Observer
import com.gdelataillade.alarm.alarm.AlarmService
import com.gdelataillade.alarm.services.AlarmRingingLiveData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shows the ring screen over the lock screen and turns the display on while
 * an alarm rings, and only then.
 *
 * The alarm plugin does this through an observer that only fires once the
 * activity is already started, which an activity launched behind the
 * keyguard never is, and it also asks to dismiss the keyguard, which puts
 * the PIN prompt on top of the Snooze button. This activity replaces that
 * observer.
 */
class MainActivity : FlutterActivity() {
    /** Set from the timer's sun button; independent of a ringing alarm. */
    private var keepScreenOnByUser = false

    private companion object {
        /** Notification channel of the alarm plugin (NotificationService). */
        const val ALARM_CHANNEL_ID = "alarm_plugin_channel"
    }

    private val ringingObserver = Observer<Boolean> { ringing ->
        // On subscribe, LiveData replays its last value, which is the stale
        // "false" of the previous alarm while a new one is starting. Only
        // switch off when nothing is ringing; the ring screen also switches
        // it off explicitly when it closes.
        if (ringing) {
            showOverLockScreen(true)
        } else if (!isAlarmRinging()) {
            showOverLockScreen(false)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Launched by the alarm's full-screen intent: the flags must be set
        // before the window is shown, or it stays hidden behind the keyguard.
        if (isAlarmRinging()) showOverLockScreen(true)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isAlarmRinging()) showOverLockScreen(true)
    }

    override fun onResume() {
        super.onResume()
        // Opened by tapping the alarm notification on the lock screen.
        if (isAlarmRinging()) showOverLockScreen(true)
    }

    override fun onStart() {
        super.onStart()
        AlarmRingingLiveData.instance.removeObservers(this)
        AlarmRingingLiveData.instance.observe(this, ringingObserver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "alarmin/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(null)
                    }
                    "setKeepScreenOn" -> {
                        keepScreenOnByUser = call.arguments as? Boolean ?: false
                        updateKeepScreenOn(ringing = isAlarmRinging())
                        result.success(null)
                    }
                    "setShowOverLockScreen" -> {
                        showOverLockScreen(call.arguments as? Boolean ?: false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAlarmRinging(): Boolean {
        if (AlarmService.ringingAlarmIds.isNotEmpty() ||
            AlarmRingingLiveData.instance.value == true
        ) {
            return true
        }
        // The plugin posts its notification (whose full-screen intent opens
        // this activity) before it records the alarm as ringing, so on launch
        // the notification is the only reliable sign.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = getSystemService(NotificationManager::class.java)
        return manager.activeNotifications.any {
            it.notification.channelId == ALARM_CHANNEL_ID
        }
    }

    private fun showOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(show)
            setTurnScreenOn(show)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) window.addFlags(flags) else window.clearFlags(flags)
        }
        updateKeepScreenOn(ringing = show)
    }

    private fun updateKeepScreenOn(ringing: Boolean) {
        if (ringing || keepScreenOnByUser) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    /** Android 14+ lets users revoke the permission that wakes the screen. */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val manager = getSystemService(NotificationManager::class.java)
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings() {
        val intent = if (Build.VERSION.SDK_INT >= 34) {
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                .setData(Uri.parse("package:$packageName"))
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:$packageName"))
        }
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}
