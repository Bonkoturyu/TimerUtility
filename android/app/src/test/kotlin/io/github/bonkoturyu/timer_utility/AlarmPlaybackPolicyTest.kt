package io.github.bonkoturyu.timer_utility

import org.junit.Assert.assertEquals
import org.junit.Test

class AlarmPlaybackPolicyTest {
    @Test
    fun volumeGainUsesNormalizedPercentage() {
        assertEquals(0f, AlarmPlaybackPolicy.volumeGain(-10), 0.0001f)
        assertEquals(0.55f, AlarmPlaybackPolicy.volumeGain(55), 0.0001f)
        assertEquals(1f, AlarmPlaybackPolicy.volumeGain(120), 0.0001f)
    }

    @Test
    fun bundledSoundIdsMapToRawResourceNames() {
        assertEquals("alarm_default", AlarmPlaybackPolicy.bundledResourceName("default"))
        assertEquals("alarm_gentle", AlarmPlaybackPolicy.bundledResourceName("gentle"))
        assertEquals("alarm_warning", AlarmPlaybackPolicy.bundledResourceName("warning"))
        assertEquals("alarm_bhutan", AlarmPlaybackPolicy.bundledResourceName("bhutan"))
        assertEquals("alarm_spain", AlarmPlaybackPolicy.bundledResourceName("spain"))
    }

    @Test
    fun unknownSoundFallsBackToDefaultResource() {
        assertEquals("alarm_default", AlarmPlaybackPolicy.bundledResourceName("missing"))
    }
}
