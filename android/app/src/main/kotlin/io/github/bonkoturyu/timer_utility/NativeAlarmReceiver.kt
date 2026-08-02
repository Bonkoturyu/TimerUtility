package io.github.bonkoturyu.timer_utility

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Dispatches an exact alarm to the service or an inexact alarm to the cue. */
class NativeAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra("notificationId", -1)
        val entry = NativeAlarmScheduler.take(context, notificationId) ?: return
        if (entry.exactPlayback) {
            AlarmPlaybackService.start(context, entry)
        } else {
            NativeAlarmNotification.showInexactCue(context, entry)
        }
    }
}
