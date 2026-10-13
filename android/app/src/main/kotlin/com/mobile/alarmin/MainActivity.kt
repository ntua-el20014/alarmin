package com.mobile.alarmin

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
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

        /** Where the alarm notification moves while the ring screen shows. */
        const val QUIET_ALARM_CHANNEL_ID = "alarm_ringing_quiet"

        /**
         * MIUI/HyperOS app ops behind "Show on lock screen" and "Display
         * pop-up windows while running in the background". Not public API,
         * but stable across MIUI versions.
         */
        const val MIUI_OP_SHOW_WHEN_LOCKED = 10020
        const val MIUI_OP_BACKGROUND_START_ACTIVITY = 10021

        /** Makers whose own lock screen setting blocks alarms, unreadable. */
        val UNVERIFIABLE_LOCK_SCREEN_MAKERS =
            setOf("vivo", "oppo", "realme", "huawei", "honor")
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
                    "openUrl" -> result.success(openUrl(call.arguments as String))
                    "lockScreenPermission" -> result.success(lockScreenPermission())
                    "openLockScreenPermissionSettings" -> {
                        openLockScreenPermissionSettings()
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
            it.notification.channelId == ALARM_CHANNEL_ID ||
                it.notification.channelId == QUIET_ALARM_CHANNEL_ID
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
        if (show) quietAlarmNotifications()
    }

    /**
     * The ring screen already shows the alarm, so the plugin's heads-up
     * notification on top of it is just clutter. It cannot be removed (it
     * keeps the ringing service alive), so it is re-posted on a minimized,
     * silent channel: it leaves the screen and the lock screen but stays in
     * the notification shade with its Stop button.
     */
    private fun quietAlarmNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        try {
            if (manager.getNotificationChannel(QUIET_ALARM_CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        QUIET_ALARM_CHANNEL_ID,
                        "Ringing alarm (while on screen)",
                        NotificationManager.IMPORTANCE_MIN,
                    ).apply { setSound(null, null) }
                )
            }
            for (active in manager.activeNotifications) {
                if (active.notification.channelId != ALARM_CHANNEL_ID) continue
                val quiet = Notification.Builder
                    .recoverBuilder(this, active.notification)
                    .setChannelId(QUIET_ALARM_CHANNEL_ID)
                    .setFullScreenIntent(null, false)
                    .build()
                manager.notify(active.tag, active.id, quiet)
            }
        } catch (e: Exception) {
            // Leave the notification as it is; the alarm still works.
        }
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

    private fun isXiaomi(): Boolean =
        Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)

    /**
     * Some makers add their own "show on lock screen" setting on top of
     * Android's, and while it is off the alarm only shows as a notification.
     * Returns "granted" or "denied" where it can be read (Xiaomi), "unknown"
     * where it exists but cannot be read, and "notNeeded" elsewhere.
     */
    private fun lockScreenPermission(): String {
        if (isXiaomi()) {
            val allowed = miuiOpAllowed(MIUI_OP_SHOW_WHEN_LOCKED) ?: return "unknown"
            val popups = miuiOpAllowed(MIUI_OP_BACKGROUND_START_ACTIVITY) ?: return "unknown"
            return if (allowed && popups) "granted" else "denied"
        }
        val maker = Build.MANUFACTURER.lowercase()
        return if (maker in UNVERIFIABLE_LOCK_SCREEN_MAKERS) "unknown" else "notNeeded"
    }

    private fun miuiOpAllowed(op: Int): Boolean? = try {
        val manager = getSystemService(AppOpsManager::class.java)
        val check = AppOpsManager::class.java.getMethod(
            "checkOpNoThrow",
            Int::class.javaPrimitiveType,
            Int::class.javaPrimitiveType,
            String::class.java,
        )
        check.invoke(manager, op, Process.myUid(), packageName) as Int ==
            AppOpsManager.MODE_ALLOWED
    } catch (e: Exception) {
        null
    }

    /** The maker's permission page for this app, or App info as a fallback. */
    private fun openLockScreenPermissionSettings() {
        val candidates = mutableListOf<Intent>()
        if (isXiaomi()) {
            for (activity in listOf(
                "com.miui.permcenter.permissions.PermissionsEditorActivity",
                "com.miui.permcenter.permissions.AppPermissionsEditorActivity",
            )) {
                candidates += Intent("miui.intent.action.APP_PERM_EDITOR")
                    .setClassName("com.miui.securitycenter", activity)
                    .putExtra("extra_pkgname", packageName)
            }
        }
        if (Build.MANUFACTURER.equals("vivo", ignoreCase = true)) {
            candidates += Intent().setClassName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity",
            ).putExtra("packagename", packageName)
        }
        candidates += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:$packageName"))
        for (intent in candidates) {
            try {
                startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (e: ActivityNotFoundException) {
                // Try the next page.
            } catch (e: SecurityException) {
                // Not exported on this OS version; try the next page.
            }
        }
    }

    private fun openUrl(url: String): Boolean = try {
        startActivity(
            Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        true
    } catch (e: ActivityNotFoundException) {
        false
    }
}
