package io.github.bonkoturyu.timer_utility

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Persists and schedules self-chaining interval notification alarms. */
object IntervalNotificationScheduler {
    private const val PREFS = "interval_notifications"
    private const val PREFIX = "timer_"

    data class Entry(
        val notificationId: Int,
        val nextFireAtUtcMs: Long,
        val intervalMs: Long,
        val title: String,
        val body: String,
        val exact: Boolean,
    )

    @Synchronized
    fun schedule(context: Context, entry: Entry) {
        require(entry.intervalMs > 0L) { "intervalMs must be positive" }
        persist(context, entry)
        scheduleAlarm(context, entry)
    }

    @Synchronized
    fun cancel(context: Context, notificationId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, notificationId))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(key(notificationId)).apply()
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.cancel(notificationId)
    }

    /**
     * Serializes firing and re-scheduling against [cancel]. If the user pauses
     * exactly at a boundary, either cancel wins first (nothing fires), or it
     * runs immediately after this method and removes the newly chained alarm.
     * The cancelled schedule can therefore never be resurrected.
     */
    @Synchronized
    fun fireAndScheduleNext(context: Context, notificationId: Int, fire: (Entry) -> Unit) {
        val entry = load(context, notificationId) ?: return
        fire(entry)
        schedule(context, next(entry, System.currentTimeMillis()))
    }

    fun loadAll(context: Context): List<Entry> {
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return preferences.all.keys
            .filter { it.startsWith(PREFIX) }
            .mapNotNull { decode(preferences.getString(it, null)) }
    }

    fun next(entry: Entry, nowUtcMs: Long): Entry {
        val elapsed = (nowUtcMs - entry.nextFireAtUtcMs).coerceAtLeast(0L)
        val steps = elapsed / entry.intervalMs + 1L
        return entry.copy(nextFireAtUtcMs = entry.nextFireAtUtcMs + steps * entry.intervalMs)
    }

    private fun scheduleAlarm(context: Context, entry: Entry) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, entry.notificationId)
        if (entry.exact) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        entry.nextFireAtUtcMs,
                        pendingIntent,
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, entry.nextFireAtUtcMs, pendingIntent)
                }
                return
            } catch (_: SecurityException) {
                // Permission can be revoked after scheduling; fall back safely.
            }
        }
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            entry.nextFireAtUtcMs,
            pendingIntent,
        )
    }

    private fun pendingIntent(context: Context, notificationId: Int): PendingIntent {
        val intent = Intent(context, IntervalNotificationReceiver::class.java).apply {
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

    private fun load(context: Context, notificationId: Int): Entry? =
        decode(
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(key(notificationId), null),
        )

    private fun key(id: Int) = "$PREFIX$id"

    private fun encode(e: Entry): String = listOf(
        e.notificationId.toString(), e.nextFireAtUtcMs.toString(), e.intervalMs.toString(),
        e.exact.toString(),
        android.util.Base64.encodeToString(e.title.toByteArray(Charsets.UTF_8), android.util.Base64.NO_WRAP),
        android.util.Base64.encodeToString(e.body.toByteArray(Charsets.UTF_8), android.util.Base64.NO_WRAP),
    ).joinToString("|")

    private fun decode(raw: String?): Entry? = try {
        val p = raw?.split('|') ?: return null
        Entry(
            p[0].toInt(), p[1].toLong(), p[2].toLong(),
            String(android.util.Base64.decode(p[4], android.util.Base64.NO_WRAP), Charsets.UTF_8),
            String(android.util.Base64.decode(p[5], android.util.Base64.NO_WRAP), Charsets.UTF_8),
            p[3].toBoolean(),
        )
    } catch (_: Exception) { null }
}
