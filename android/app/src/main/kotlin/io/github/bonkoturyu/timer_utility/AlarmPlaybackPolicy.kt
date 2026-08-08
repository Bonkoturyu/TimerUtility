package io.github.bonkoturyu.timer_utility

/** Pure playback policy shared by the Android service and local JUnit tests. */
object AlarmPlaybackPolicy {
    const val DEFAULT_VOLUME_PERCENT = 100

    fun normalizeVolumePercent(percent: Int): Int = percent.coerceIn(0, 100)

    fun volumeGain(percent: Int): Float = normalizeVolumePercent(percent) / 100f

    fun bundledResourceName(soundId: String): String = when (soundId) {
        "gentle" -> "alarm_gentle"
        "warning" -> "alarm_warning"
        "bhutan" -> "alarm_bhutan"
        "spain" -> "alarm_spain"
        else -> "alarm_default"
    }
}
