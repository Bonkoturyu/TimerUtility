package io.github.bonkoturyu.timer_utility

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Re-registers future alarms after reboot or application replacement. */
class NativeAlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val now = System.currentTimeMillis()
        for (entry in NativeAlarmScheduler.loadAll(context)) {
            if (entry.fireAtUtcMs > now) {
                NativeAlarmScheduler.schedule(context, entry)
            } else {
                NativeAlarmScheduler.cancel(context, entry.notificationId)
            }
        }
    }
}
