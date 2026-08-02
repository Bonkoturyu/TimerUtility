package io.github.bonkoturyu.timer_utility

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Base64

/** Persists one-shot alarms and selects exact or inexact AlarmManager APIs. */
object NativeAlarmScheduler {
    private const val PREFS = "native_alarm_schedules"
    private const val PREFIX = "alarm_"

    data class Entry(
        val notificationId: Int,
        val fireAtUtcMs: Long,
        val title: String,
        val body: String,
        val payload: String,
        val soundId: String,
        val soundPath: String?,
        val exactPlayback: Boolean = true,
    )

    @Synchronized
    fun schedule(context: Context, requested: Entry) {
        cancelAlarmManager(context, requested.notificationId)
        val exact = canScheduleExact(context)
        val entry = requested.copy(exactPlayback = exact)
        persist(context, entry)
        if (exact && scheduleExact(context, entry)) return

        val fallback = entry.copy(exactPlayback = false)
        persist(context, fallback)
        scheduleInexact(context, fallback)
    }

    @Synchronized
    fun cancel(context: Context, notificationId: Int) {
        cancelAlarmManager(context, notificationId)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(key(notificationId)).apply()
        if (AlarmPlaybackSessionStore.activeNotificationId(context) != notificationId) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.cancel(notificationId)
        }
    }

    @Synchronized
    fun cancelAll(context: Context) {
        for (entry in loadAll(context)) cancelAlarmManager(context, entry.notificationId)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    @Synchronized
    fun take(context: Context, notificationId: Int): Entry? {
        val entry = load(context, notificationId) ?: return null
        cancelAlarmManager(context, notificationId)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(key(notificationId)).apply()
        return entry
    }

    @Synchronized
    fun ensurePlayback(context: Context, notificationId: Int): Boolean {
        if (notificationId < 0) {
            return AlarmPlaybackService.isActive(context)
        }
        if (AlarmPlaybackService.isActive(context, notificationId)) return true
        val entry = take(context, notificationId) ?: return false
        if (!entry.exactPlayback) {
            // The inexact cue path must preserve the 3.2-second Flutter
            // handoff rather than silently changing to Native playback.
            persist(context, entry)
            scheduleInexact(context, entry)
            return false
        }
        AlarmPlaybackService.start(context, entry)
        return true
    }

    fun loadAll(context: Context): List<Entry> {
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return preferences.all.keys
            .filter { it.startsWith(PREFIX) }
            .mapNotNull { decode(preferences.getString(it, null)) }
    }

    private fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return manager.canScheduleExactAlarms()
    }

    private fun scheduleExact(context: Context, entry: Entry): Boolean = try {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            entry.fireAtUtcMs,
            pendingIntent(context, entry.notificationId),
        )
        true
    } catch (_: SecurityException) {
        false
    }

    private fun scheduleInexact(context: Context, entry: Entry) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            entry.fireAtUtcMs,
            pendingIntent(context, entry.notificationId),
        )
    }

    private fun cancelAlarmManager(context: Context, notificationId: Int) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(pendingIntent(context, notificationId))
    }

    private fun pendingIntent(context: Context, notificationId: Int): PendingIntent {
        val intent = Intent(context, NativeAlarmReceiver::class.java).apply {
            putExtra("notificationId", notificationId)
        }
        return PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun persist(context: Context, entry: Entry) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(key(entry.notificationId), encode(entry)).apply()
    }

    private fun load(context: Context, notificationId: Int): Entry? = decode(
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(notificationId), null),
    )

    private fun key(notificationId: Int): String = "$PREFIX$notificationId"

    private fun encode(entry: Entry): String = listOf(
        entry.notificationId.toString(),
        entry.fireAtUtcMs.toString(),
        entry.exactPlayback.toString(),
        encodeText(entry.title),
        encodeText(entry.body),
        encodeText(entry.payload),
        encodeText(entry.soundId),
        encodeText(entry.soundPath ?: ""),
    ).joinToString("|")

    private fun decode(raw: String?): Entry? {
        return try {
            val parts = raw?.split('|') ?: return null
            if (parts.size != 8) return null
            Entry(
                notificationId = parts[0].toInt(),
                fireAtUtcMs = parts[1].toLong(),
                exactPlayback = parts[2].toBooleanStrict(),
                title = decodeText(parts[3]),
                body = decodeText(parts[4]),
                payload = decodeText(parts[5]),
                soundId = decodeText(parts[6]),
                soundPath = decodeText(parts[7]).ifEmpty { null },
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun encodeText(value: String): String = Base64.encodeToString(
        value.toByteArray(Charsets.UTF_8),
        Base64.NO_WRAP,
    )

    private fun decodeText(value: String): String = String(
        Base64.decode(value, Base64.NO_WRAP),
        Charsets.UTF_8,
    )
}
