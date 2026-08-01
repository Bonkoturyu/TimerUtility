package io.github.bonkoturyu.timer_utility

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OnDeviceSpeechRecognitionPolicyTest {
    @Test
    fun `モデル確認用specには認識用optionを含めない`() {
        val spec = OnDeviceSpeechRecognitionPolicy.modelIntentSpec("ja-JP")

        assertEquals("ja-JP", spec.localeTag)
        assertNull(spec.maxResults)
        assertNull(spec.partialResults)
        assertNull(spec.biasingPhrases)
    }

    @Test
    fun `認識用specには候補数と部分認識とbias phraseを含める`() {
        val phrases = mutableListOf("停止", "stop")

        val spec = OnDeviceSpeechRecognitionPolicy.listeningIntentSpec(
            localeTag = "ja-JP",
            biasingPhrases = phrases,
        )
        phrases.clear()

        assertEquals("ja-JP", spec.localeTag)
        assertEquals(5, spec.maxResults)
        assertEquals(false, spec.partialResults)
        assertEquals(listOf("停止", "stop"), spec.biasingPhrases)
    }

    @Test
    fun `完全一致する取得済み言語はreadyになる`() {
        val status = supportStatus(installed = listOf("ja-JP"))

        assertEquals(OnDeviceSpeechSupportStatus.READY, status)
    }

    @Test
    fun `完全一致する取得待ち言語はdownload pendingになる`() {
        val status = supportStatus(pending = listOf("ja-JP"))

        assertEquals(OnDeviceSpeechSupportStatus.DOWNLOAD_PENDING, status)
    }

    @Test
    fun `完全一致する取得可能言語はdownload requiredになる`() {
        val status = supportStatus(downloadable = listOf("ja-JP"))

        assertEquals(OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED, status)
    }

    @Test
    fun `API 34以降の空リストはcallback付きモデル取得へ進める`() {
        val status = supportStatus(downloadCallbacksAvailable = true)

        assertEquals(OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED, status)
    }

    @Test
    fun `API 33の空リストは永続的なpendingにせずunavailableになる`() {
        val status = supportStatus(downloadCallbacksAvailable = false)

        assertEquals(OnDeviceSpeechSupportStatus.UNAVAILABLE, status)
    }

    @Test
    fun `language onlyの日本語はja JPに一致する`() {
        val status = supportStatus(installed = listOf("ja"))

        assertEquals(OnDeviceSpeechSupportStatus.READY, status)
    }

    @Test
    fun `language onlyの中国語は簡体字にも繁体字にもreadyとして一致しない`() {
        val simplified = supportStatus(
            installed = listOf("zh"),
            localeTag = "zh-CN",
        )
        val traditional = supportStatus(
            installed = listOf("zh"),
            localeTag = "zh-TW",
        )

        assertFalse(simplified == OnDeviceSpeechSupportStatus.READY)
        assertFalse(traditional == OnDeviceSpeechSupportStatus.READY)
    }

    @Test
    fun `明示的な言語非対応errorだけをunsupportedにする`() {
        val unsupported = OnDeviceSpeechRecognitionPolicy.supportErrorStatus(
            OnDeviceSpeechSupportError.LANGUAGE_NOT_SUPPORTED,
        )
        val unavailable = OnDeviceSpeechRecognitionPolicy.supportErrorStatus(
            OnDeviceSpeechSupportError.LANGUAGE_UNAVAILABLE,
        )
        val other = OnDeviceSpeechRecognitionPolicy.supportErrorStatus(
            OnDeviceSpeechSupportError.OTHER,
        )

        assertEquals(OnDeviceSpeechSupportStatus.UNSUPPORTED, unsupported)
        assertEquals(OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED, unavailable)
        assertEquals(OnDeviceSpeechSupportStatus.UNAVAILABLE, other)
        assertTrue(unsupported.wireValue == "unsupported")
    }

    private fun supportStatus(
        installed: List<String> = emptyList(),
        pending: List<String> = emptyList(),
        downloadable: List<String> = emptyList(),
        localeTag: String = "ja-JP",
        downloadCallbacksAvailable: Boolean = true,
    ): OnDeviceSpeechSupportStatus = OnDeviceSpeechRecognitionPolicy.supportStatus(
        installedLanguages = installed,
        pendingLanguages = pending,
        downloadableLanguages = downloadable,
        localeTag = localeTag,
        downloadCallbacksAvailable = downloadCallbacksAvailable,
    )
}
