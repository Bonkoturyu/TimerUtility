package io.github.bonkoturyu.timer_utility

import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.IBinder
import android.os.PowerManager
import java.io.File

/** Owns looping exact-alarm audio independently from the Flutter process. */
class AlarmPlaybackService : Service() {
    private var player: MediaPlayer? = null
    private var notificationId: Int? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE_VOLUME -> {
                applyVolume(AlarmPlaybackSessionStore.volumePercent(this))
                return START_NOT_STICKY
            }
        }

        val entry = intent?.toEntry() ?: run {
            stopSelf()
            return START_NOT_STICKY
        }
        startEntry(entry)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releasePlayer()
        notificationId?.let { AlarmPlaybackSessionStore.clearActive(this, it) }
        notificationId = null
        active = false
        super.onDestroy()
    }

    private fun startEntry(entry: NativeAlarmScheduler.Entry) {
        val previousNotificationId = notificationId
        releasePlayer()
        notificationId = entry.notificationId
        active = true
        AlarmPlaybackSessionStore.setActive(this, entry.notificationId, entry.payload)
        startForeground(
            entry.notificationId,
            NativeAlarmNotification.buildForeground(this, entry),
        )
        if (previousNotificationId != null && previousNotificationId != entry.notificationId) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.cancel(previousNotificationId)
        }

        player = createPlayer(entry).also { mediaPlayer ->
            mediaPlayer.setOnErrorListener { _, _, _ ->
                stopSelf()
                true
            }
            mediaPlayer.start()
        }
    }

    private fun createPlayer(entry: NativeAlarmScheduler.Entry): MediaPlayer {
        val mediaPlayer = MediaPlayer()
        try {
            mediaPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            mediaPlayer.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
            mediaPlayer.isLooping = true
            applyVolumeTo(mediaPlayer, AlarmPlaybackSessionStore.volumePercent(this))
            val imported = entry.soundPath?.let(::File)?.takeIf { it.isFile }
            if (imported != null) {
                mediaPlayer.setDataSource(imported.absolutePath)
            } else {
                val resourceName = AlarmPlaybackPolicy.bundledResourceName(entry.soundId)
                val resourceId = resources.getIdentifier(resourceName, "raw", packageName)
                    .takeIf { it != 0 } ?: R.raw.alarm_default
                mediaPlayer.setDataSource(
                    this,
                    Uri.parse("android.resource://$packageName/$resourceId"),
                )
            }
            mediaPlayer.prepare()
            return mediaPlayer
        } catch (error: Exception) {
            mediaPlayer.release()
            if (entry.soundId == "default" && entry.soundPath == null) throw error
            return createPlayer(entry.copy(soundId = "default", soundPath = null))
        }
    }

    private fun applyVolume(percent: Int) {
        player?.let { applyVolumeTo(it, percent) }
    }

    private fun applyVolumeTo(mediaPlayer: MediaPlayer, percent: Int) {
        val gain = AlarmPlaybackPolicy.volumeGain(percent)
        mediaPlayer.setVolume(gain, gain)
    }

    private fun releasePlayer() {
        player?.runCatching { stop() }
        player?.release()
        player = null
    }

    companion object {
        @Volatile
        private var active = false

        private const val ACTION_START =
            "io.github.bonkoturyu.timer_utility.action.START_ALARM_PLAYBACK"
        private const val ACTION_STOP =
            "io.github.bonkoturyu.timer_utility.action.STOP_ALARM_PLAYBACK"
        private const val ACTION_UPDATE_VOLUME =
            "io.github.bonkoturyu.timer_utility.action.UPDATE_ALARM_VOLUME"

        private const val EXTRA_ID = "notificationId"
        private const val EXTRA_FIRE_AT = "fireAtUtcMs"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_PAYLOAD = "payload"
        private const val EXTRA_SOUND_ID = "soundId"
        private const val EXTRA_SOUND_PATH = "soundPath"

        fun start(context: Context, entry: NativeAlarmScheduler.Entry) {
            val intent = Intent(context, AlarmPlaybackService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_ID, entry.notificationId)
                putExtra(EXTRA_FIRE_AT, entry.fireAtUtcMs)
                putExtra(EXTRA_TITLE, entry.title)
                putExtra(EXTRA_BODY, entry.body)
                putExtra(EXTRA_PAYLOAD, entry.payload)
                putExtra(EXTRA_SOUND_ID, entry.soundId)
                putExtra(EXTRA_SOUND_PATH, entry.soundPath)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmPlaybackService::class.java))
            AlarmPlaybackSessionStore.clearActive(context)
        }

        fun setVolumePercent(context: Context, percent: Int) {
            AlarmPlaybackSessionStore.setVolumePercent(context, percent)
            if (active) {
                context.startService(
                    Intent(context, AlarmPlaybackService::class.java).apply {
                        action = ACTION_UPDATE_VOLUME
                    },
                )
            }
        }

        fun isActive(context: Context, notificationId: Int? = null): Boolean {
            if (!active) {
                AlarmPlaybackSessionStore.clearActive(context)
                return false
            }
            return notificationId == null ||
                AlarmPlaybackSessionStore.activeNotificationId(context) == notificationId
        }

        fun activePayload(context: Context): String? =
            if (isActive(context)) AlarmPlaybackSessionStore.activePayload(context) else null

        private fun Intent.toEntry(): NativeAlarmScheduler.Entry? {
            val id = getIntExtra(EXTRA_ID, -1)
            val fireAt = getLongExtra(EXTRA_FIRE_AT, -1L)
            val title = getStringExtra(EXTRA_TITLE)
            val body = getStringExtra(EXTRA_BODY)
            val payload = getStringExtra(EXTRA_PAYLOAD)
            val soundId = getStringExtra(EXTRA_SOUND_ID)
            if (id < 0 || fireAt < 0 || title == null || body == null ||
                payload == null || soundId == null) return null
            return NativeAlarmScheduler.Entry(
                notificationId = id,
                fireAtUtcMs = fireAt,
                title = title,
                body = body,
                payload = payload,
                soundId = soundId,
                soundPath = getStringExtra(EXTRA_SOUND_PATH),
                exactPlayback = true,
            )
        }
    }
}
