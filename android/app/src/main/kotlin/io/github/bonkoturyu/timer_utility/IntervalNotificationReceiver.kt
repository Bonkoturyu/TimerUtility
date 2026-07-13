package io.github.bonkoturyu.timer_utility

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import java.util.concurrent.atomic.AtomicBoolean

/** Emits one short alarm-stream sound, then schedules the next fixed boundary. */
class IntervalNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("notificationId", -1)
        val pendingResult = goAsync()
        var fired = false
        IntervalNotificationScheduler.fireAndScheduleNext(context, id) { entry ->
            fired = true
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            ensureIntervalChannel(context, notificationManager)
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val contentIntent = launch?.let {
                PendingIntent.getActivity(
                    context, id, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }
            val notification = Notification.Builder(context, INTERVAL_CHANNEL_ID)
                .setSmallIcon(context.applicationInfo.icon)
                .setContentTitle(entry.title)
                .setContentText(entry.body)
                .setCategory(Notification.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(contentIntent)
                .build()
            notificationManager.notify(id, notification)
            playShortAlarmSound(context, pendingResult)
        }
        if (!fired) pendingResult.finish()
    }

    private fun ensureIntervalChannel(context: Context, manager: NotificationManager) {
        val channel = NotificationChannel(
            INTERVAL_CHANNEL_ID,
            context.getString(R.string.interval_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(null, null)
            enableVibration(true)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun playShortAlarmSound(context: Context, pendingResult: PendingResult) {
        val finished = AtomicBoolean(false)
        val handler = Handler(Looper.getMainLooper())
        var player: MediaPlayer? = null
        fun finish() {
            if (!finished.compareAndSet(false, true)) return
            handler.removeCallbacksAndMessages(null)
            player?.runCatching { stop() }
            player?.release()
            player = null
            pendingResult.finish()
        }

        try {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(
                    context,
                    Uri.parse("android.resource://${context.packageName}/${R.raw.alarm_default}"),
                )
                setOnCompletionListener { finish() }
                setOnErrorListener { _, _, _ ->
                    finish()
                    true
                }
                prepare()
                start()
            }
            handler.postDelayed({ finish() }, SOUND_DURATION_MS)
        } catch (_: Exception) {
            finish()
        }
    }

    companion object {
        private const val INTERVAL_CHANNEL_ID = "timer_interval_v1"
        private const val SOUND_DURATION_MS = 2_000L
    }
}
