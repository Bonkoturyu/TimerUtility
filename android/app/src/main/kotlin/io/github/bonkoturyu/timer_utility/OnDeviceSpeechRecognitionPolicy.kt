package io.github.bonkoturyu.timer_utility

import java.util.Locale

internal data class OnDeviceSpeechIntentSpec(
    val localeTag: String,
    val maxResults: Int? = null,
    val partialResults: Boolean? = null,
    val biasingPhrases: List<String>? = null,
)

internal enum class OnDeviceSpeechSupportStatus(val wireValue: String) {
    READY("ready"),
    DOWNLOAD_REQUIRED("download_required"),
    DOWNLOAD_PENDING("download_pending"),
    UNSUPPORTED("unsupported"),
    UNAVAILABLE("unavailable"),
}

internal enum class OnDeviceSpeechSupportError {
    LANGUAGE_NOT_SUPPORTED,
    LANGUAGE_UNAVAILABLE,
    OTHER,
}

/** Pure Kotlin policy for request construction and language-model state. */
internal object OnDeviceSpeechRecognitionPolicy {
    private val languageOnlyFallbacks = setOf("ja", "ko")

    fun modelIntentSpec(localeTag: String): OnDeviceSpeechIntentSpec =
        OnDeviceSpeechIntentSpec(localeTag = localeTag)

    fun listeningIntentSpec(
        localeTag: String,
        biasingPhrases: List<String>,
    ): OnDeviceSpeechIntentSpec = OnDeviceSpeechIntentSpec(
        localeTag = localeTag,
        maxResults = 5,
        partialResults = false,
        biasingPhrases = biasingPhrases.toList(),
    )

    fun supportStatus(
        installedLanguages: List<String>,
        pendingLanguages: List<String>,
        downloadableLanguages: List<String>,
        localeTag: String,
        downloadCallbacksAvailable: Boolean,
    ): OnDeviceSpeechSupportStatus = when {
        installedLanguages.matches(localeTag) -> OnDeviceSpeechSupportStatus.READY
        pendingLanguages.matches(localeTag) -> OnDeviceSpeechSupportStatus.DOWNLOAD_PENDING
        downloadableLanguages.matches(localeTag) ->
            OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED
        downloadCallbacksAvailable -> OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED
        else -> OnDeviceSpeechSupportStatus.UNAVAILABLE
    }

    fun supportErrorStatus(
        error: OnDeviceSpeechSupportError,
    ): OnDeviceSpeechSupportStatus = when (error) {
        OnDeviceSpeechSupportError.LANGUAGE_NOT_SUPPORTED ->
            OnDeviceSpeechSupportStatus.UNSUPPORTED
        OnDeviceSpeechSupportError.LANGUAGE_UNAVAILABLE ->
            OnDeviceSpeechSupportStatus.DOWNLOAD_REQUIRED
        OnDeviceSpeechSupportError.OTHER -> OnDeviceSpeechSupportStatus.UNAVAILABLE
    }

    private fun List<String>.matches(localeTag: String): Boolean {
        val requestedLocale = Locale.forLanguageTag(localeTag)
        val requestedTag = requestedLocale.toLanguageTag()
        return any { candidate ->
            val candidateLocale = Locale.forLanguageTag(candidate)
            candidateLocale.toLanguageTag().equals(requestedTag, ignoreCase = true) ||
                (
                    candidateLocale.country.isEmpty() &&
                        candidateLocale.script.isEmpty() &&
                        candidateLocale.language in languageOnlyFallbacks &&
                        candidateLocale.language.equals(
                            requestedLocale.language,
                            ignoreCase = true,
                        )
                )
        }
    }
}
