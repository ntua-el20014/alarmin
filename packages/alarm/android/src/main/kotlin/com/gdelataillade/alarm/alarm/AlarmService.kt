package com.gdelataillade.alarm.alarm

import com.gdelataillade.alarm.services.AudioService
import com.gdelataillade.alarm.services.AlarmStorage
import com.gdelataillade.alarm.services.VibrationService
import com.gdelataillade.alarm.services.VolumeService
import com.gdelataillade.alarm.models.NotificationSettings
import com.google.gson.Gson

import android.app.Service
import android.app.PendingIntent
import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.content.Intent
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.IBinder
import android.os.PowerManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.gdelataillade.alarm.services.AlarmRingingLiveData
import com.gdelataillade.alarm.services.NotificationHandler
import io.flutter.Log

class AlarmService : Service() {
    private var audioService: AudioService? = null
    private var vibrationService: VibrationService? = null
    private var volumeService: VolumeService? = null
    private var showSystemUI: Boolean = true
    private val handler = Handler(Looper.getMainLooper())
    private val ringTimeouts = mutableMapOf<Int, Runnable>()

    companion object {
        @JvmStatic
        var ringingAlarmIds: List<Int> = listOf()

        /** Alarmin patch: how long an alarm rings before it goes quiet. */
        const val RING_TIMEOUT_MS = 40_000L
    }

    override fun onCreate() {
        super.onCreate()

        audioService = AudioService(this)
        vibrationService = VibrationService(this)
        volumeService = VolumeService(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val id = intent.getIntExtra("id", 0)
        val action = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_ACTION)

        if (action == "STOP_ALARM" && id != 0) {
            unsaveAlarm(id)
            return START_NOT_STICKY
        }

        // Build the notification
        val notificationHandler = NotificationHandler(this)
        val appIntent =
            applicationContext.packageManager.getLaunchIntentForPackage(applicationContext.packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            appIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notificationSettingsJson = intent.getStringExtra("notificationSettings")
        val notificationSettings = if (notificationSettingsJson != null) {
            val gson = Gson()
            gson.fromJson(notificationSettingsJson, NotificationSettings::class.java)
        } else {
            val notificationTitle = intent.getStringExtra("notificationTitle") ?: "Title"
            val notificationBody = intent.getStringExtra("notificationBody") ?: "Body"
            NotificationSettings(notificationTitle, notificationBody)
        }

        val fullScreenIntent = intent.getBooleanExtra("fullScreenIntent", true)
        val notification = notificationHandler.buildNotification(
            notificationSettings,
            fullScreenIntent,
            pendingIntent,
            id
        )

        // Start the service in the foreground
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    startAlarmService(id, notification)
                } catch (e: ForegroundServiceStartNotAllowedException) {
                    Log.e("AlarmService", "Foreground service start not allowed", e)
                    return START_NOT_STICKY
                }
            } else {
                startAlarmService(id, notification)
            }
        } catch (e: SecurityException) {
            Log.e("AlarmService", "Security exception in starting foreground service", e)
            return START_NOT_STICKY
        }

        // Check if an alarm is already ringing
        if (ringingAlarmIds.isNotEmpty() && action != "STOP_ALARM") {
            Log.d("AlarmService", "An alarm is already ringing. Ignoring new alarm with id: $id")
            unsaveAlarm(id)
            return START_NOT_STICKY
        }

        if (fullScreenIntent) {
            AlarmRingingLiveData.instance.update(true)
            // Alarmin patch: do not depend on Android honouring the full-screen
            // intent (on Android 14+ it is downgraded to a plain notification
            // without the full-screen permission, and some OEMs block it).
            wakeScreen()
            appIntent?.let { openApp(it) }
        }

        // Proceed with handling the new alarm
        val assetAudioPath = intent.getStringExtra("assetAudioPath") ?: return START_NOT_STICKY
        val loopAudio = intent.getBooleanExtra("loopAudio", true)
        val vibrate = intent.getBooleanExtra("vibrate", true)
        val volume = intent.getDoubleExtra("volume", -1.0)
        val volumeEnforced = intent.getBooleanExtra("volumeEnforced", false)
        val fadeDuration = intent.getDoubleExtra("fadeDuration", 0.0)

        // Notify the plugin about the alarm ringing
        AlarmPlugin.alarmTriggerApi?.alarmRang(id.toLong()) {
            Log.d("AlarmService", "Flutter was notified that alarm $id is ringing.")
        }

        // Set the volume if specified
        if (volume in 0.0..1.0) {
            volumeService?.setVolume(volume, volumeEnforced, showSystemUI)
        }

        // Request audio focus
        volumeService?.requestAudioFocus()

        // Set up audio completion listener
        audioService?.setOnAudioCompleteListener {
            if (!loopAudio) {
                vibrationService?.stopVibrating()
                volumeService?.restorePreviousVolume(showSystemUI)
                volumeService?.abandonAudioFocus()
            }
        }

        // Play the alarm audio
        audioService?.playAudio(id, assetAudioPath, loopAudio, fadeDuration)
        scheduleRingTimeout(id)

        // Update the list of ringing alarms
        ringingAlarmIds = audioService?.getPlayingMediaPlayersIds() ?: listOf()

        // Start vibration if enabled
        if (vibrate) {
            vibrationService?.startVibrating(longArrayOf(0, 500, 500), 1)
        }

        // Acquire a wake lock to wake up the device
        val wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "app:AlarmWakelockTag")
        wakeLock.acquire(5 * 60 * 1000L) // Acquire for 5 minutes

        return START_STICKY
    }

    /**
     * Alarmin patch: an alarm nobody answers stops by itself after
     * [RING_TIMEOUT_MS], exactly like a Stop from the notification, so the
     * app reschedules it and its reminders ring again later. Runs natively so
     * it also works while the app is killed.
     */
    private fun scheduleRingTimeout(id: Int) {
        cancelRingTimeout(id)
        val timeout = Runnable {
            ringTimeouts.remove(id)
            unsaveAlarm(id)
        }
        ringTimeouts[id] = timeout
        handler.postDelayed(timeout, RING_TIMEOUT_MS)
    }

    private fun cancelRingTimeout(id: Int) {
        ringTimeouts.remove(id)?.let { handler.removeCallbacks(it) }
    }

    /** Alarmin patch: turns the display on, like the Clock app. */
    private fun wakeScreen() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val screenLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                "alarmin:AlarmScreenOn"
            )
            screenLock.acquire(10 * 1000L)
        } catch (e: Exception) {
            Log.e("AlarmService", "Could not wake the screen: ${e.message}")
        }
    }

    /**
     * Alarmin patch: opens the app (which shows its ring screen over the lock
     * screen) directly. Android only allows this from the background when the
     * app may draw over other apps; otherwise the full-screen intent and the
     * notification remain the way in.
     */
    private fun openApp(appIntent: Intent) {
        val allowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            Settings.canDrawOverlays(this)
        if (!allowed) return
        try {
            startActivity(
                Intent(appIntent).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                )
            )
        } catch (e: Exception) {
            Log.e("AlarmService", "Could not open the app: ${e.message}")
        }
    }

    private fun startAlarmService(id: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                id,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(id, notification)
        }
    }

    private fun unsaveAlarm(id: Int) {
        AlarmStorage(this).unsaveAlarm(id)
        AlarmPlugin.alarmTriggerApi?.alarmStopped(id.toLong()) {
            Log.d("AlarmService", "Flutter was notified that alarm $id was stopped.")
        }
        stopAlarm(id)
    }

    private fun stopAlarm(id: Int) {
        cancelRingTimeout(id)
        AlarmRingingLiveData.instance.update(false)
        try {
            val playingIds = audioService?.getPlayingMediaPlayersIds() ?: listOf()
            ringingAlarmIds = playingIds

            // Safely call methods on 'volumeService' and 'audioService'
            volumeService?.restorePreviousVolume(showSystemUI)
            volumeService?.abandonAudioFocus()

            audioService?.stopAudio(id)

            // Check if media player is empty safely
            if (audioService?.isMediaPlayerEmpty() == true) {
                vibrationService?.stopVibrating()
                stopSelf()
            }

            stopForeground(true)
        } catch (e: IllegalStateException) {
            Log.e("AlarmService", "Illegal State: ${e.message}", e)
        } catch (e: Exception) {
            Log.e("AlarmService", "Error in stopping alarm: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        ringingAlarmIds = listOf()
        handler.removeCallbacksAndMessages(null)
        ringTimeouts.clear()

        audioService?.cleanUp()
        vibrationService?.stopVibrating()
        volumeService?.restorePreviousVolume(showSystemUI)
        volumeService?.abandonAudioFocus()

        AlarmRingingLiveData.instance.update(false)

        stopForeground(true)

        // Call the superclass method
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
