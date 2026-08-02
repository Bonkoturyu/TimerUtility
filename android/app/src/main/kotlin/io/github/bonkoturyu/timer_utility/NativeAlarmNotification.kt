package io.github.bonkoturyu.timer_utility

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

/** Creates alarm notifications for both Native playback and cue fallback. */
object NativeAlarmNotification {
    const val AUDIBLE_CHANNEL_ID = "timer_alarm_v7"
    const val SILENT_CHANNEL_ID = "timer_alarm_native_v1"

    fun showInexactCue(context: Context, entry: NativeAlarmScheduler.Entry) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannels(context, manager)
        manager.notify(entry.notificationId, build(context, entry, foreground = false))
    }

    fun buildForeground(context: Context, entry: NativeAlarmScheduler.Entry): Notification {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannels(context, manager)
        return build(context, entry, foreground = true)
    }

    private fun ensureChannels(context: Context, manager: NotificationManager) {
        val name = context.getString(R.string.alarm_notification_channel_name)
        val cueUri = Uri.parse(
            "android.resource://${context.packageName}/${R.raw.notif_alert}",
        )
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        manager.createNotificationChannel(
            NotificationChannel(
                AUDIBLE_CHANNEL_ID,
                name,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(cueUri, attributes)
                enableVibration(true)
                setShowBadge(false)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                SILENT_CHANNEL_ID,
                name,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(null, null)
                enableVibration(true)
                setShowBadge(false)
            },
        )
    }

    private fun build(
        context: Context,
        entry: NativeAlarmScheduler.Entry,
        foreground: Boolean,
    ): Notification {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "${context.packageName}.ALARM.${entry.notificationId}"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_ALARM_PAYLOAD, entry.payload)
            putExtra(MainActivity.EXTRA_ALARM_NOTIFICATION_ID, entry.notificationId)
        }
        val launchPendingIntent = PendingIntent.getActivity(
            context,
            entry.notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = Notification.Builder(
            context,
            if (foreground) SILENT_CHANNEL_ID else AUDIBLE_CHANNEL_ID,
        )
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(entry.title)
            .setContentText(entry.body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(launchPendingIntent)
            .setAutoCancel(!foreground)
            .setOngoing(foreground)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val canUseFullScreenIntent = Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
            manager.canUseFullScreenIntent()
        if (canUseFullScreenIntent) {
            builder.setFullScreenIntent(launchPendingIntent, true)
        }
        return builder.build()
    }
}
