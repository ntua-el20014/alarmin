package com.mobile.alarmin

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.format.DateFormat
import com.gdelataillade.alarm.api.AlarmApiImpl
import com.gdelataillade.alarm.services.AlarmStorage
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date

/**
 * The quiet "upcoming alarm" notification shown an hour before an alarm,
 * with a Skip button that works while the app is closed.
 *
 * Notices are stored by slot (see `noticeSlotId` in alarm_service.dart), so
 * they can be re-armed after a reboot and so scheduling the same occurrence
 * again does not bring back a notification the user swiped away. Skip
 * cancels the occurrence's native alarms right away and records the skip;
 * the Dart side then moves the saved alarm past it (`takeSkipped`).
 */
object UpcomingAlarms {
    private const val CHANNEL_ID = "upcoming_alarms"
    private const val LEAD_MS = 60 * 60 * 1000L
    private const val PREFS = "alarmin_upcoming"
    private const val NOTICE_PREFIX = "notice_"
    private const val KEY_SKIPPED = "skipped"
    const val ACTION_SHOW = "com.mobile.alarmin.UPCOMING_SHOW"
    const val ACTION_SKIP = "com.mobile.alarmin.UPCOMING_SKIP"
    const val EXTRA_SLOT = "slot"

    /** Set by MainActivity while its Flutter engine runs. */
    @Volatile
    var onSkipped: (() -> Unit)? = null

    private data class Notice(
        val slot: Int,
        val alarmId: String,
        val occurrence: Long,
        val title: String,
        val nativeIds: List<Int>,
        val posted: Boolean,
    ) {
        fun toJson(): String = JSONObject()
            .put("slot", slot)
            .put("alarmId", alarmId)
            .put("occurrence", occurrence)
            .put("title", title)
            .put("nativeIds", JSONArray(nativeIds))
            .put("posted", posted)
            .toString()

        companion object {
            fun fromJson(json: String): Notice? = try {
                val o = JSONObject(json)
                val ids = o.getJSONArray("nativeIds")
                Notice(
                    slot = o.getInt("slot"),
                    alarmId = o.getString("alarmId"),
                    occurrence = o.getLong("occurrence"),
                    title = o.getString("title"),
                    nativeIds = List(ids.length()) { ids.getInt(it) },
                    posted = o.getBoolean("posted"),
                )
            } catch (e: Exception) {
                null
            }
        }
    }

    fun schedule(
        context: Context,
        slot: Int,
        alarmId: String,
        occurrence: Long,
        title: String,
        nativeIds: List<Int>,
    ) {
        val stored = load(context, slot)
        if (stored != null &&
            stored.alarmId == alarmId &&
            stored.occurrence == occurrence
        ) {
            // Same occurrence: keep whether it was shown (or swiped away).
            val updated = stored.copy(title = title, nativeIds = nativeIds)
            save(context, updated)
            if (!updated.posted) arm(context, updated)
            return
        }
        cancel(context, slot)
        if (occurrence <= System.currentTimeMillis()) return
        val notice = Notice(slot, alarmId, occurrence, title, nativeIds, posted = false)
        save(context, notice)
        arm(context, notice)
    }

    fun cancel(context: Context, slot: Int) {
        alarmManager(context).cancel(showIntent(context, slot))
        notificationManager(context).cancel(slot)
        prefs(context).edit().remove("$NOTICE_PREFIX$slot").apply()
    }

    /** Skips recorded since the last call, as `{alarmId, occurrence}` maps. */
    fun takeSkipped(context: Context): List<Map<String, Any>> {
        val raw = prefs(context).getString(KEY_SKIPPED, null) ?: return emptyList()
        prefs(context).edit().remove(KEY_SKIPPED).apply()
        val array = try {
            JSONArray(raw)
        } catch (e: Exception) {
            return emptyList()
        }
        return List(array.length()) {
            val o = array.getJSONObject(it)
            mapOf("alarmId" to o.getString("alarmId"), "occurrence" to o.getLong("occurrence"))
        }
    }

    fun onShow(context: Context, slot: Int) {
        val notice = load(context, slot) ?: return
        if (notice.posted || notice.occurrence <= System.currentTimeMillis()) return
        post(context, notice)
    }

    fun onSkip(context: Context, slot: Int) {
        val notice = load(context, slot) ?: return
        val api = AlarmApiImpl(context)
        val storage = AlarmStorage(context)
        for (id in notice.nativeIds) {
            api.stopAlarm(id.toLong())
            storage.unsaveAlarm(id)
        }
        val skipped = try {
            JSONArray(prefs(context).getString(KEY_SKIPPED, "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
        skipped.put(
            JSONObject().put("alarmId", notice.alarmId).put("occurrence", notice.occurrence)
        )
        // Kept as posted, so rescheduling this occurrence shows nothing.
        prefs(context).edit()
            .putString(KEY_SKIPPED, skipped.toString())
            .putString("$NOTICE_PREFIX$slot", notice.copy(posted = true).toJson())
            .apply()
        notificationManager(context).cancel(slot)
        onSkipped?.let { callback -> Handler(Looper.getMainLooper()).post { callback() } }
    }

    /** Alarm manager entries do not survive a reboot. */
    fun rearmAll(context: Context) {
        val now = System.currentTimeMillis()
        for ((key, value) in prefs(context).all) {
            if (!key.startsWith(NOTICE_PREFIX) || value !is String) continue
            val notice = Notice.fromJson(value) ?: continue
            if (notice.occurrence <= now) {
                prefs(context).edit().remove(key).apply()
            } else if (!notice.posted) {
                arm(context, notice)
            }
        }
    }

    private fun arm(context: Context, notice: Notice) {
        val triggerAt = notice.occurrence - LEAD_MS
        if (triggerAt <= System.currentTimeMillis()) {
            post(context, notice)
            return
        }
        val manager = alarmManager(context)
        val intent = showIntent(context, notice.slot)
        try {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, intent)
        } catch (e: SecurityException) {
            // Exact alarms not allowed: a few minutes late is fine here.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, intent)
        }
    }

    private fun post(context: Context, notice: Notice) {
        val manager = notificationManager(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL_ID) == null
        ) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Upcoming alarms",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "A silent reminder an hour before an alarm, with a Skip button"
                    setShowBadge(false)
                }
            )
        }

        val time = DateFormat.getTimeFormat(context).format(Date(notice.occurrence))
        val skip = PendingIntent.getBroadcast(
            context,
            notice.slot,
            Intent(context, UpcomingAlarmReceiver::class.java)
                .setAction(ACTION_SKIP)
                .putExtra(EXTRA_SLOT, notice.slot),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.let {
                PendingIntent.getActivity(
                    context,
                    notice.slot,
                    it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }

        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
                .setTimeoutAfter(notice.occurrence - System.currentTimeMillis())
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setContentTitle(notice.title)
            .setContentText("Upcoming alarm at $time")
            .setCategory(Notification.CATEGORY_REMINDER)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Skip", skip).build())
            .build()
        try {
            manager.notify(notice.slot, notification)
        } catch (e: SecurityException) {
            return // Notifications not allowed.
        }
        save(context, notice.copy(posted = true))
    }

    private fun showIntent(context: Context, slot: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            slot,
            Intent(context, UpcomingAlarmReceiver::class.java)
                .setAction(ACTION_SHOW)
                .putExtra(EXTRA_SLOT, slot),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun load(context: Context, slot: Int): Notice? =
        prefs(context).getString("$NOTICE_PREFIX$slot", null)?.let(Notice::fromJson)

    private fun save(context: Context, notice: Notice) {
        prefs(context).edit().putString("$NOTICE_PREFIX${notice.slot}", notice.toJson()).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun notificationManager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}

class UpcomingAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val slot = intent.getIntExtra(UpcomingAlarms.EXTRA_SLOT, 0)
        when (intent.action) {
            UpcomingAlarms.ACTION_SHOW -> UpcomingAlarms.onShow(context, slot)
            UpcomingAlarms.ACTION_SKIP -> UpcomingAlarms.onSkip(context, slot)
        }
    }
}

/** Separate from [UpcomingAlarmReceiver] so that one need not be exported. */
class UpcomingAlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> UpcomingAlarms.rearmAll(context)
        }
    }
}
