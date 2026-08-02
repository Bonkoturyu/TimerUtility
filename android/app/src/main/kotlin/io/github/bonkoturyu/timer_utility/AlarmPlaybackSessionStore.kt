package io.github.bonkoturyu.timer_utility

import android.content.Context

/** Persists the app-owned volume and the currently active Native session. */
object AlarmPlaybackSessionStore {
    private const val PREFS = "native_alarm_playback"
    private const val KEY_VOLUME = "volume_percent"
    private const val KEY_ACTIVE_ID = "active_notification_id"
    private const val KEY_ACTIVE_PAYLOAD = "active_payload"

    fun volumePercent(context: Context): Int = AlarmPlaybackPolicy.normalizeVolumePercent(
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_VOLUME, AlarmPlaybackPolicy.DEFAULT_VOLUME_PERCENT),
    )

    fun setVolumePercent(context: Context, percent: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt(KEY_VOLUME, AlarmPlaybackPolicy.normalizeVolumePercent(percent))
            .apply()
    }

    fun setActive(context: Context, notificationId: Int, payload: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt(KEY_ACTIVE_ID, notificationId)
            .putString(KEY_ACTIVE_PAYLOAD, payload)
            .apply()
    }

    fun activeNotificationId(context: Context): Int? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return if (prefs.contains(KEY_ACTIVE_ID)) prefs.getInt(KEY_ACTIVE_ID, -1) else null
    }

    fun activePayload(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ACTIVE_PAYLOAD, null)

    fun clearActive(context: Context, expectedNotificationId: Int? = null) {
        if (expectedNotificationId != null && activeNotificationId(context) != expectedNotificationId) {
            return
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(KEY_ACTIVE_ID)
            .remove(KEY_ACTIVE_PAYLOAD)
            .apply()
    }
}
