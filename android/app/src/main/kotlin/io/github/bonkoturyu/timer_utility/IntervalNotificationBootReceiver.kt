package io.github.bonkoturyu.timer_utility

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores interval alarms after reboot or application replacement. */
class IntervalNotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val now = System.currentTimeMillis()
        for (entry in IntervalNotificationScheduler.loadAll(context)) {
            val future = if (entry.nextFireAtUtcMs > now) entry
            else IntervalNotificationScheduler.next(entry, now)
            IntervalNotificationScheduler.schedule(context, future)
        }
    }
}
